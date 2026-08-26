import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late InventoryDatabase database;

  setUp(() {
    database = InventoryDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('creates, finds, archives, and restores an item', () async {
    await database.saveItem(_item(id: 'item-1'), [
      _code(itemId: 'item-1', value: 'LAB-001'),
    ]);

    final created = await database.itemByCode('LAB-001');
    expect(created?.item.name, 'Bench multimeter');
    expect(await database.watchItems(archived: false).first, hasLength(1));

    await database.setArchived('item-1', archived: true);
    expect(await database.watchItems(archived: false).first, isEmpty);
    expect(await database.watchItems(archived: true).first, hasLength(1));

    await database.setArchived('item-1', archived: false);
    expect(await database.watchItems(archived: false).first, hasLength(1));
  });

  test('keeps code values unique, including archived items', () async {
    await database.saveItem(_item(id: 'item-1'), [
      _code(itemId: 'item-1', value: 'LAB-001'),
    ]);
    await database.setArchived('item-1', archived: true);

    expect(
      () => database.saveItem(_item(id: 'item-2'), [
        _code(itemId: 'item-2', value: 'LAB-001'),
      ]),
      throwsA(isA<SqliteException>()),
    );
  });

  test('finds an item by item, 1P, or 1T code', () async {
    await database.saveItem(
      _item(id: 'item-1', configuration: ItemCodeConfiguration.packageAndItem),
      [
        _code(itemId: 'item-1', value: 'ITEM-001'),
        _code(
          itemId: 'item-1',
          value: 'PART-001',
          role: ItemCodeRole.package1P,
        ),
        _code(
          itemId: 'item-1',
          value: 'TRACE-001',
          role: ItemCodeRole.package1T,
        ),
      ],
    );

    for (final value in ['ITEM-001', 'PART-001', 'TRACE-001']) {
      expect((await database.itemByCode(value))?.item.id, 'item-1');
    }
  });

  test(
    'migrates an existing item code into the normalized code table',
    () async {
      await database.close();
      final directory = await Directory.systemTemp.createTemp('inventory-v1-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}legacy.sqlite',
      );
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute('''
      CREATE TABLE inventory_items (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        item_type TEXT NOT NULL,
        category TEXT NOT NULL,
        serial_number TEXT,
        code_type TEXT NOT NULL,
        code_value TEXT NOT NULL UNIQUE,
        code_source TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        archived_at INTEGER
      );
      INSERT INTO inventory_items (
        id, name, item_type, category, serial_number, code_type, code_value,
        code_source, created_at, updated_at, is_archived
      ) VALUES (
        'legacy-1', 'Legacy meter', 'equipment', 'Test equipment', NULL,
        'code128', 'LEGACY-001', 'scanned', 1787616000, 1787616000, 0
      );
      PRAGMA user_version = 1;
    ''');
      legacy.close();

      final migrated = InventoryDatabase.forTesting(NativeDatabase(file));
      try {
        final entry = await migrated.itemByCode('LEGACY-001');
        expect(entry?.item.id, 'legacy-1');
        expect(entry?.item.codeConfiguration, ItemCodeConfiguration.itemOnly);
        expect(entry?.codeFor(ItemCodeRole.item)?.value, 'LEGACY-001');
      } finally {
        await migrated.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

InventoryItemsCompanion _item({
  required String id,
  ItemCodeConfiguration configuration = ItemCodeConfiguration.itemOnly,
}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: const Value('Bench multimeter'),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test equipment'),
    serialNumber: const Value('SN-100'),
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
