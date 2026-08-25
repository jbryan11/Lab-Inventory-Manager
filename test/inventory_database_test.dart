import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';

void main() {
  late InventoryDatabase database;

  setUp(() {
    database = InventoryDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('creates, finds, archives, and restores an item', () async {
    await database.saveItem(_item(id: 'item-1', code: 'LAB-001'));

    final created = await database.itemByCode('LAB-001');
    expect(created?.name, 'Bench multimeter');
    expect(await database.watchItems(archived: false).first, hasLength(1));

    await database.setArchived('item-1', archived: true);
    expect(await database.watchItems(archived: false).first, isEmpty);
    expect(await database.watchItems(archived: true).first, hasLength(1));

    await database.setArchived('item-1', archived: false);
    expect(await database.watchItems(archived: false).first, hasLength(1));
  });

  test('keeps code values unique, including archived items', () async {
    await database.saveItem(_item(id: 'item-1', code: 'LAB-001'));
    await database.setArchived('item-1', archived: true);

    expect(
      () => database.saveItem(_item(id: 'item-2', code: 'LAB-001')),
      throwsA(isA<SqliteException>()),
    );
  });
}

InventoryItemsCompanion _item({required String id, required String code}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: const Value('Bench multimeter'),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test equipment'),
    serialNumber: const Value('SN-100'),
    codeType: const Value(ItemCodeType.code128),
    codeValue: Value(code),
    codeSource: const Value(ItemCodeSource.scanned),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}
