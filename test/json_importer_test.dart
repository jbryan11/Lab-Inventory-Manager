import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/services/json_importer.dart';

void main() {
  group('JsonImporter', () {
    late InventoryDatabase database;
    late JsonImporter importer;
    late Directory temporaryDirectory;

    setUp(() async {
      database = InventoryDatabase.forTesting(NativeDatabase.memory());
      importer = JsonImporter(database);
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'json-importer-test-',
      );
    });

    tearDown(() async {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    });

    test('imports items and codes from the exported JSON structure', () async {
      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, _payload()),
      );

      expect(result.success, isTrue);
      expect(result.itemsImported, 1);
      expect(result.codesImported, 2);
      expect(result.errors, isEmpty);

      final entry = await database.itemById('item-1');
      expect(entry?.item.name, 'Imported meter');
      expect(entry?.item.itemType, LabItemType.equipment);
      expect(entry?.codeFor(ItemCodeRole.item)?.value, 'ITEM-001');
      expect(entry?.codeFor(ItemCodeRole.package1P)?.value, 'PART-001');
    });

    test('replaces an existing item and its codes by item id', () async {
      await database.saveItem(_item(id: 'item-1', name: 'Old name'), [
        _code(itemId: 'item-1', value: 'OLD-CODE'),
      ]);

      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, _payload()),
      );

      expect(result.success, isTrue);
      expect(result.itemsImported, 1);
      final entry = await database.itemById('item-1');
      expect(entry?.item.name, 'Imported meter');
      expect(
        entry?.codes.map((code) => code.value),
        isNot(contains('OLD-CODE')),
      );
      expect(entry?.codes, hasLength(2));
    });

    test('imports legacy exports with codes nested under items', () async {
      final payload = _payload();
      final item = (payload['items'] as List).single as Map<String, Object?>;
      item['codes'] = (payload.remove('codes') as List)
          .map(
            (code) => Map<String, Object?>.from(code as Map)..remove('itemId'),
          )
          .toList();

      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, payload),
      );

      expect(result.success, isTrue);
      expect(result.itemsImported, 1);
      expect(result.codesImported, 2);
      expect((await database.itemById('item-1'))?.codes, hasLength(2));
    });

    test('reports code conflicts without changing the database', () async {
      await database.saveItem(_item(id: 'existing', name: 'Existing item'), [
        _code(itemId: 'existing', value: 'ITEM-001'),
      ]);

      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, _payload()),
      );

      expect(result.success, isFalse);
      expect(result.itemsImported, 0);
      expect(result.codesImported, 0);
      expect(result.errors.single, contains('already belongs'));
      expect(await database.itemById('item-1'), isNull);
      expect((await database.itemByCode('ITEM-001'))?.item.id, 'existing');
    });

    test('rejects malformed JSON structure with a useful error', () async {
      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, {
          'items': [
            {'id': 'item-1'},
          ],
        }),
      );

      expect(result.success, isFalse);
      expect(result.itemsImported, 0);
      expect(result.errors.single, contains('items and codes must be arrays'));
    });

    test('rejects invalid records without importing valid records', () async {
      final payload = _payload();
      (payload['items'] as List).add({
        'id': 'item-2',
        'name': '',
        'itemType': 'tool',
        'category': 'Tools',
        'codeConfiguration': 'itemOnly',
        'isArchived': false,
        'createdAt': '2026-08-25T00:00:00.000Z',
        'updatedAt': '2026-08-25T00:00:00.000Z',
      });

      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, payload),
      );

      expect(result.success, isFalse);
      expect(
        result.errors,
        contains(contains('name must be a non-empty string')),
      );
      expect(await database.allItems(), isEmpty);
    });

    test('rolls back every record when the database rejects one', () async {
      final payload = _payload();
      (payload['items'] as List).add({
        ..._itemJson(id: 'item-2'),
        'name': List.filled(201, 'x').join(),
      });

      final result = await importer.importFromFile(
        await _writeJson(temporaryDirectory, payload),
      );

      expect(result.success, isFalse);
      expect(result.itemsImported, 0);
      expect(await database.allItems(), isEmpty);
    });
  });
}

Map<String, Object?> _payload() => {
  'schemaVersion': 2,
  'items': [_itemJson(id: 'item-1')],
  'codes': [
    {
      'itemId': 'item-1',
      'role': 'item',
      'type': 'code128',
      'value': 'ITEM-001',
      'source': 'scanned',
    },
    {
      'itemId': 'item-1',
      'role': 'package1P',
      'type': 'qr',
      'value': 'PART-001',
      'source': 'generated',
    },
  ],
};

Map<String, Object?> _itemJson({required String id}) => {
  'id': id,
  'name': 'Imported meter',
  'itemType': 'equipment',
  'category': 'Test equipment',
  'serialNumber': 'SN-100',
  'codeConfiguration': 'packageAndItem',
  'isArchived': false,
  'createdAt': '2026-08-25T00:00:00.000Z',
  'updatedAt': '2026-08-25T01:00:00.000Z',
  'archivedAt': null,
};

Future<File> _writeJson(
  Directory directory,
  Map<String, Object?> payload,
) async {
  final file = File('${directory.path}${Platform.pathSeparator}inventory.json');
  return file.writeAsString(jsonEncode(payload));
}

InventoryItemsCompanion _item({required String id, required String name}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: Value(name),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test equipment'),
    codeConfiguration: const Value(ItemCodeConfiguration.itemOnly),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}

InventoryItemCodesCompanion _code({
  required String itemId,
  required String value,
}) {
  return InventoryItemCodesCompanion.insert(
    itemId: itemId,
    role: ItemCodeRole.item,
    codeType: ItemCodeType.code128,
    value: value,
    source: ItemCodeSource.scanned,
  );
}
