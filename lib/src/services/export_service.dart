import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../data/inventory_database.dart';
import '../domain/inventory_enums.dart';

class ExportService {
  ExportService(
    this._database, {
    Future<Directory> Function()? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final InventoryDatabase _database;
  final Future<Directory> Function() _documentsDirectory;

  Future<File> exportJson() async {
    try {
      AppLogger.info('Starting JSON export...');
      final items = await _database.allItems();
      AppLogger.debug('Exporting ${items.length} items to JSON');

      final payload = buildJsonPayload(items);

      final file = await _writeExport(
        'lab-inventory-${_timestamp()}.json',
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      AppLogger.info('JSON export completed successfully: ${file.path}');
      return file;
    } catch (e, st) {
      AppLogger.error('JSON export failed', e, st);
      throw FileException(
        'Failed to export JSON: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<File> exportCsv() async {
    try {
      AppLogger.info('Starting CSV export...');
      final items = await _database.allItems();
      AppLogger.debug('Exporting ${items.length} items to CSV');

      final csv = buildCsv(items);

      final file = await _writeExport('lab-inventory-${_timestamp()}.csv', csv);
      AppLogger.info('CSV export completed successfully: ${file.path}');
      return file;
    } catch (e, st) {
      AppLogger.error('CSV export failed', e, st);
      throw FileException(
        'Failed to export CSV: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Object?> buildJsonPayload(
    List<InventoryEntry> items, {
    DateTime? exportedAt,
  }) {
    return {
      'schemaVersion': 2,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'items': items.map(_itemToJson).toList(),
      'codes': items
          .expand(
            (entry) => entry.codes.map(
              (code) => {
                'itemId': entry.item.id,
                'role': code.role.name,
                'type': code.codeType.name,
                'value': code.value,
                'source': code.source.name,
              },
            ),
          )
          .toList(),
    };
  }

  String buildCsv(List<InventoryEntry> items) {
    final rows = <List<Object?>>[
      const [
        'id',
        'name',
        'itemType',
        'category',
        'serialNumber',
        'codeConfiguration',
        'itemCode',
        'package1P',
        'package1T',
        'isArchived',
        'createdAt',
        'updatedAt',
        'archivedAt',
      ],
      ...items.map(
        (entry) => [
          entry.item.id,
          entry.item.name,
          entry.item.itemType.name,
          entry.item.category,
          entry.item.serialNumber ?? '',
          entry.item.codeConfiguration.name,
          entry.codeFor(ItemCodeRole.item)?.value ?? '',
          entry.codeFor(ItemCodeRole.package1P)?.value ?? '',
          entry.codeFor(ItemCodeRole.package1T)?.value ?? '',
          entry.item.isArchived,
          entry.item.createdAt.toUtc().toIso8601String(),
          entry.item.updatedAt.toUtc().toIso8601String(),
          entry.item.archivedAt?.toUtc().toIso8601String() ?? '',
        ],
      ),
    ];
    return const ListToCsvConverter(eol: '\r\n').convert(rows);
  }

  Future<void> share(File file) async {
    try {
      AppLogger.info('Sharing file: ${file.path}');
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      AppLogger.info('File shared successfully');
    } catch (e, st) {
      AppLogger.error('Failed to share file', e, st);
      throw FileException(
        'Failed to share file: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Object?> _itemToJson(InventoryEntry entry) {
    final item = entry.item;
    return {
      'id': item.id,
      'name': item.name,
      'itemType': item.itemType.name,
      'category': item.category,
      'serialNumber': item.serialNumber,
      'codeConfiguration': item.codeConfiguration.name,
      'codes': entry.codes
          .map(
            (code) => {
              'role': code.role.name,
              'type': code.codeType.name,
              'value': code.value,
              'source': code.source.name,
            },
          )
          .toList(),
      'isArchived': item.isArchived,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      'archivedAt': item.archivedAt?.toUtc().toIso8601String(),
    };
  }

  Future<File> _writeExport(String name, String contents) async {
    try {
      AppLogger.debug('Writing export file: $name');
      final documents = await _documentsDirectory();
      final directory = Directory(p.join(documents.path, 'exports'));
      await directory.create(recursive: true);
      final file = File(p.join(directory.path, name));
      await file.writeAsString(contents, encoding: utf8, flush: true);
      AppLogger.debug('Export file written successfully: ${file.path}');
      return file;
    } catch (e, st) {
      AppLogger.error('Failed to write export file', e, st);
      throw FileException(
        'Failed to write export file: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  String _timestamp() =>
      DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
}
