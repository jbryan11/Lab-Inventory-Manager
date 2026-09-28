import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
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

    test(
      'builds a parseable JSON payload with items and top-level codes',
      () async {
        await database.saveItem(
          _item(
            id: 'item-1',
            configuration: ItemCodeConfiguration.packageAndItem,
          ),
          [
            _code(itemId: 'item-1', value: 'ITEM-001'),
            _code(
              itemId: 'item-1',
              value: 'PKG-1P',
              role: ItemCodeRole.package1P,
            ),
          ],
        );
        final exportedAt = DateTime.utc(2026, 9, 28, 8, 30);

        final payload = exportService.buildJsonPayload(
          await database.allItems(),
          exportedAt: exportedAt,
        );
        final parsed = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

        expect(parsed['schemaVersion'], 2);
        expect(parsed['exportedAt'], exportedAt.toIso8601String());
        expect(parsed['items'], hasLength(1));
        expect(parsed['codes'], hasLength(2));
        expect(
          (parsed['codes'] as List).map((code) => code['itemId']),
          everyElement('item-1'),
        );
      },
    );

    test('CSV has the stable spreadsheet column order', () async {
      final csv = exportService.buildCsv(const []);
      final rows = _parse(csv);

      expect(rows, hasLength(1));
      expect(rows.single, [
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
      ]);
    });

    test(
      'CSV round trip preserves commas, quotes, newlines, and Unicode',
      () async {
        const name = 'Precision, "bench"\nmeter';
        const category = '測試 equipment';
        const serial = 'SN,\n"100"';
        const codeValue = 'CODE, "A"\n1';
        await database.saveItem(
          _item(
            id: 'item-1',
            name: name,
            category: category,
            serialNumber: serial,
          ),
          [_code(itemId: 'item-1', value: codeValue)],
        );

        final csv = exportService.buildCsv(await database.allItems());
        final rows = _parse(csv);

        expect(csv, contains('\r\n'));
        expect(rows, hasLength(2));
        expect(rows[1][1], name);
        expect(rows[1][3], category);
        expect(rows[1][4], serial);
        expect(rows[1][6], codeValue);
      },
    );

    test('CSV includes all code roles and empty optional values', () async {
      await database.saveItem(
        _item(
          id: 'item-1',
          configuration: ItemCodeConfiguration.packageAndItem,
          serialNumber: null,
        ),
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

      final row = _parse(exportService.buildCsv(await database.allItems()))
          .singleWhere((row) => row.first == 'item-1');

      expect(row[4], '');
      expect(row[6], 'ITEM-001');
      expect(row[7], 'PKG-1P');
      expect(row[8], 'PKG-1T');
      expect(row[9], 'false');
      expect(row[12], '');
    });

    test('CSV includes archived state and ISO-8601 timestamps', () async {
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'ITEM-001'),
      ]);
      await database.setArchived('item-1', archived: true);

      final row = _parse(exportService.buildCsv(await database.allItems()))
          .singleWhere((row) => row.first == 'item-1');

      expect(row[9], 'true');
      expect(DateTime.tryParse(row[10] as String), isNotNull);
      expect(DateTime.tryParse(row[11] as String), isNotNull);
      expect(DateTime.tryParse(row[12] as String), isNotNull);
    });

    test('CSV emits one record per inventory item', () async {
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'ITEM-001'),
      ]);
      await database.saveItem(_item(id: 'item-2'), [
        _code(itemId: 'item-2', value: 'ITEM-002'),
      ]);

      final rows = _parse(exportService.buildCsv(await database.allItems()));

      expect(rows, hasLength(3));
      expect(rows.skip(1).map((row) => row.first), {'item-1', 'item-2'});
    });
  });
}

List<List<dynamic>> _parse(String csv) {
  return const CsvToListConverter(
    eol: '\r\n',
    shouldParseNumbers: false,
  ).convert(csv);
}

InventoryItemsCompanion _item({
  required String id,
  String name = 'Test item',
  String category = 'Test',
  String? serialNumber = 'SN-001',
  ItemCodeConfiguration configuration = ItemCodeConfiguration.itemOnly,
}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: Value(name),
    itemType: const Value(LabItemType.equipment),
    category: Value(category),
    serialNumber: Value(serialNumber),
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
