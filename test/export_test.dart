import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/services/export_service.dart';

void main() {
  group('ExportService', () {
    late InventoryDatabase database;
    late ExportService exportService;

    setUp(() {
      database = InventoryDatabase.forTesting(NativeDatabase.memory());
      exportService = ExportService(database);
    });

    tearDown(() => database.close());

    group('JSON Export', () {
      test('exports inventory with correct schema version and timestamp', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
        ]);

        final json = await exportService._itemToJson(
          await database.itemById('item-1') as InventoryEntry,
        );

        expect(json['id'], 'item-1');
        expect(json['name'], 'Test item');
        expect(json['itemType'], 'equipment');
        expect(json['category'], 'Test');
        expect(json['codes'], isA<List>());
        expect(json['isArchived'], false);
        expect(json['createdAt'], isNotNull);
      });

      test('exports all code roles in JSON', () async {
        await database.saveItem(
          _item(id: 'item-1', configuration: ItemCodeConfiguration.packageAndItem),
          [
            _code(itemId: 'item-1', value: 'ITEM-001'),
            _code(
              itemId: 'item-1',
              value: 'PKG-1P',
              role: ItemCodeRole.package1P,
            ),
            _code(
              itemId: 'item-1',
              value: 'PKG-1T',
              role: ItemCodeRole.package1T,
            ),
          ],
        );

        final entry = await database.itemById('item-1') as InventoryEntry;
        final json = await exportService._itemToJson(entry);

        expect((json['codes'] as List).length, 3);
        expect(
          (json['codes'] as List).map((c) => c['role']),
          contains('item'),
        );
        expect(
          (json['codes'] as List).map((c) => c['role']),
          contains('package1P'),
        );
      });

      test('includes archived items in export', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
        ]);
        await database.setArchived('item-1', archived: true);

        final json = await exportService._itemToJson(
          await database.itemById('item-1') as InventoryEntry,
        );

        expect(json['isArchived'], true);
        expect(json['archivedAt'], isNotNull);
      });

      test('JSON export is valid and parseable', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
        ]);
        await database.saveItem(_item(id: 'item-2'), [
          _code(itemId: 'item-2', value: 'ITEM-002'),
        ]);

        final items = await database.allItems();
        final payload = <String, Object?>{
          'schemaVersion': 2,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'items': items.map(exportService._itemToJson).toList(),
        };
        final jsonString = jsonEncode(payload);
        final parsed = jsonDecode(jsonString);

        expect(parsed['schemaVersion'], 2);
        expect((parsed['items'] as List).length, 2);
      });
    });

    group('CSV Export', () {
      test('generates CSV with correct headers', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
        ]);

        final items = await database.allItems();
        final rows = <List<Object?>>[
          [
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

        expect(rows.first.length, 13);
        expect(rows.first.contains('id'), true);
        expect(rows.first.contains('itemCode'), true);
        expect(rows.first.contains('package1P'), true);
      });

      test('escapes CSV special characters in cell values', () async {
        final service = ExportService(database);
        final cell1 = service._csvCell('value with "quotes"');
        final cell2 = service._csvCell('value,with,commas');
        final cell3 = service._csvCell('normal');

        expect(cell1, '"value with ""quotes"""');
        expect(cell2, '"value,with,commas"');
        expect(cell3, '"normal"');
      });

      test('CSV output is parseable as rows', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
        ]);

        final items = await database.allItems();
        final rows = <List<Object?>>[
          [
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
        final csv = rows.map((row) => row.map((v) => '"${v?.toString() ?? ""}"').join(',')).join('\r\n');

        expect(csv.split('\r\n').length, 2); // header + 1 item
        expect(csv.contains('item-1'), true);
        expect(csv.contains('ITEM-001'), true);
      });

      test('handles missing codes gracefully in CSV', () async {
        await database.saveItem(_item(id: 'item-1'), [
          _code(itemId: 'item-1', value: 'ITEM-001'),
          // No package codes
        ]);

        final items = await database.allItems();
        expect(items.first.codeFor(ItemCodeRole.package1P), isNull);
        expect(items.first.codeFor(ItemCodeRole.package1T), isNull);

        final rows = <List<Object?>>[
          [
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

        expect(rows[1][7], ''); // package1P is empty
        expect(rows[1][8], ''); // package1T is empty
      });
    });
  });
}

InventoryItemsCompanion _item({
  required String id,
  ItemCodeConfiguration configuration = ItemCodeConfiguration.itemOnly,
}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: const Value('Test item'),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test'),
    serialNumber: const Value('SN-001'),
    codeConfiguration: Value(configuration),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}

InventoryItemCodesCompanion _code({
  required String itemId,
  required String value,
  ItemCodeRole role = ItemCodeRole.item,
}) {
  return InventoryItemCodesCompanion.insert(
    itemId: itemId,
    role: role,
    codeType: ItemCodeType.code128,
    value: value,
    source: ItemCodeSource.scanned,
  );
}
