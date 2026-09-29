import 'dart:convert';
import 'dart:io';

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../data/inventory_database.dart';
import '../domain/inventory_enums.dart';

class ImportResult {
  ImportResult({
    required this.itemsImported,
    required this.codesImported,
    required List<String> errors,
    required this.success,
  }) : errors = List.unmodifiable(errors);

  factory ImportResult.failure(String error) => ImportResult(
    itemsImported: 0,
    codesImported: 0,
    errors: [error],
    success: false,
  );

  final int itemsImported;
  final int codesImported;
  final List<String> errors;
  final bool success;
}

class JsonImporter {
  JsonImporter(this._database);

  final InventoryDatabase _database;

  Future<ImportResult> importFromFile(File file) async {
    AppLogger.info('Starting JSON import from: ${file.path}');

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      final json = _validateImportStructure(decoded);
      final result = await _importData(json);

      if (result.success) {
        AppLogger.info(
          'JSON import completed: ${result.itemsImported} items, '
          '${result.codesImported} codes',
        );
      } else {
        AppLogger.warning(
          'JSON import rejected with ${result.errors.length} error(s)',
        );
      }
      return result;
    } on FormatException catch (error, stackTrace) {
      AppLogger.error('JSON import contains malformed JSON', error, stackTrace);
      return ImportResult.failure('The selected file is not valid JSON.');
    } on FileSystemException catch (error, stackTrace) {
      AppLogger.error('Could not read JSON import file', error, stackTrace);
      return ImportResult.failure('Could not read the selected file.');
    } on ValidationException catch (error, stackTrace) {
      AppLogger.error('JSON import validation failed', error, stackTrace);
      return ImportResult.failure(error.message);
    } catch (error, stackTrace) {
      AppLogger.error('JSON import failed', error, stackTrace);
      return ImportResult.failure('Import failed: $error');
    }
  }

  Map<String, dynamic> _validateImportStructure(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw ValidationException('Invalid JSON: the root must be an object.');
    }
    final items = decoded['items'];
    if (items is! List) {
      throw ValidationException(
        'Invalid JSON structure: items and codes must be arrays.',
      );
    }
    if (decoded['codes'] is List) return decoded;

    // Schema-v2 exports originally stored codes inside each item.
    if (decoded['codes'] == null &&
        items.every(
          (item) =>
              item is Map<String, dynamic> &&
              item['id'] is String &&
              item['codes'] is List,
        )) {
      AppLogger.warning(
        'Import file uses legacy nested codes; normalizing to schema v2.',
      );
      return {
        ...decoded,
        'codes': [
          for (final item in items.cast<Map<String, dynamic>>())
            for (final code in item['codes'] as List)
              if (code is Map<String, dynamic>)
                {...code, 'itemId': item['id']}
              else
                code,
        ],
      };
    }

    throw ValidationException(
      'Invalid JSON structure: items and codes must be arrays.',
    );
  }

  Future<ImportResult> _importData(Map<String, dynamic> json) async {
    final errors = <String>[];
    final items = <InventoryItem>[];
    final codes = <InventoryItemCodesCompanion>[];

    for (final entry in (json['items'] as List).indexed) {
      try {
        items.add(_parseItem(entry.$2));
      } on ValidationException catch (error) {
        errors.add('Item ${entry.$1 + 1}: ${error.message}');
      }
    }
    for (final entry in (json['codes'] as List).indexed) {
      try {
        codes.add(_parseCode(entry.$2));
      } on ValidationException catch (error) {
        errors.add('Code ${entry.$1 + 1}: ${error.message}');
      }
    }

    _validateRelationships(items, codes, errors);
    if (errors.isNotEmpty) {
      return ImportResult(
        itemsImported: 0,
        codesImported: 0,
        errors: errors,
        success: false,
      );
    }

    final existingEntries = await _database.allItems();
    final importedIds = items.map((item) => item.id).toSet();
    final importedValues = {
      for (final code in codes) code.value.value: code.itemId.value,
    };
    for (final entry in existingEntries) {
      if (importedIds.contains(entry.item.id)) continue;
      for (final code in entry.codes) {
        final importedItemId = importedValues[code.value];
        if (importedItemId != null) {
          errors.add(
            'Code "${code.value}" already belongs to "${entry.item.name}".',
          );
        }
      }
    }
    if (errors.isNotEmpty) {
      return ImportResult(
        itemsImported: 0,
        codesImported: 0,
        errors: errors,
        success: false,
      );
    }

    try {
      await _database.transaction(() async {
        await _database.batch(
          (batch) =>
              batch.insertAllOnConflictUpdate(_database.inventoryItems, items),
        );
        await (_database.delete(
          _database.inventoryItemCodes,
        )..where((row) => row.itemId.isIn(importedIds))).go();
        if (codes.isNotEmpty) {
          await _database.batch(
            (batch) => batch.insertAll(_database.inventoryItemCodes, codes),
          );
        }
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Database transaction failed during JSON import',
        error,
        stackTrace,
      );
      return ImportResult.failure(
        'No data was imported because the database rejected the file.',
      );
    }

    return ImportResult(
      itemsImported: items.length,
      codesImported: codes.length,
      errors: const [],
      success: true,
    );
  }

  void _validateRelationships(
    List<InventoryItem> items,
    List<InventoryItemCodesCompanion> codes,
    List<String> errors,
  ) {
    final itemIds = <String>{};
    for (final item in items) {
      if (!itemIds.add(item.id)) {
        errors.add('Duplicate item id "${item.id}".');
      }
    }

    final codeValues = <String>{};
    final itemRoles = <String>{};
    for (final code in codes) {
      final itemId = code.itemId.value;
      final value = code.value.value;
      if (!itemIds.contains(itemId)) {
        errors.add('Code "$value" references unknown item "$itemId".');
      }
      if (!codeValues.add(value)) {
        errors.add('Duplicate code value "$value".');
      }
      if (!itemRoles.add('$itemId:${code.role.value.name}')) {
        errors.add(
          'Item "$itemId" has more than one ${code.role.value.name} code.',
        );
      }
    }
  }

  InventoryItem _parseItem(Object? value) {
    final json = _asObject(value, 'item');
    final id = _requiredString(json, 'id');
    final name = _requiredString(json, 'name');
    final category = _requiredString(json, 'category');
    final serialNumber = _optionalString(json, 'serialNumber');
    final archivedAt = _optionalDateTime(json, 'archivedAt');

    return InventoryItem(
      id: id,
      name: name,
      itemType: _enumValue(json, 'itemType', LabItemType.values),
      category: category,
      serialNumber: serialNumber,
      codeConfiguration: _enumValue(
        json,
        'codeConfiguration',
        ItemCodeConfiguration.values,
      ),
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
      isArchived: _requiredBool(json, 'isArchived'),
      archivedAt: archivedAt,
    );
  }

  InventoryItemCodesCompanion _parseCode(Object? value) {
    final json = _asObject(value, 'code');
    return InventoryItemCodesCompanion.insert(
      itemId: _requiredString(json, 'itemId'),
      role: _enumValue(json, 'role', ItemCodeRole.values),
      codeType: _enumValue(json, 'type', ItemCodeType.values),
      value: normalizeCodeValue(_requiredString(json, 'value')),
      source: _enumValue(json, 'source', ItemCodeSource.values),
    );
  }

  Map<String, dynamic> _asObject(Object? value, String label) {
    if (value is! Map<String, dynamic>) {
      throw ValidationException('$label must be an object.');
    }
    return value;
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.trim().isEmpty) {
      throw ValidationException('$field must be a non-empty string.');
    }
    return value.trim();
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is! String) {
      throw ValidationException('$field must be a string or null.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! bool) {
      throw ValidationException('$field must be a boolean.');
    }
    return value;
  }

  DateTime _requiredDateTime(Map<String, dynamic> json, String field) {
    final value = _requiredString(json, field);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw ValidationException('$field must be an ISO-8601 date.');
    }
    return parsed.toUtc();
  }

  DateTime? _optionalDateTime(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is! String || DateTime.tryParse(value) == null) {
      throw ValidationException('$field must be an ISO-8601 date or null.');
    }
    return DateTime.parse(value).toUtc();
  }

  T _enumValue<T extends Enum>(
    Map<String, dynamic> json,
    String field,
    List<T> values,
  ) {
    final name = _requiredString(json, field);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ValidationException(
      '$field must be one of: ${values.map((value) => value.name).join(', ')}.',
    );
  }
}
