import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/inventory_enums.dart';

part 'inventory_database.g.dart';

class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get itemType => textEnum<LabItemType>()();
  TextColumn get category => text().withLength(min: 1, max: 100)();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get codeType => textEnum<ItemCodeType>()();
  TextColumn get codeValue => text().withLength(min: 1, max: 500).unique()();
  TextColumn get codeSource => textEnum<ItemCodeSource>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [InventoryItems])
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase() : super(_openConnection());

  InventoryDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Stream<List<InventoryItem>> watchItems({required bool archived}) {
    final query = select(inventoryItems)
      ..where((row) => row.isArchived.equals(archived))
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.watch();
  }

  Future<List<InventoryItem>> allItems() {
    final query = select(inventoryItems)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.get();
  }

  Future<InventoryItem?> itemById(String id) {
    return (select(
      inventoryItems,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<InventoryItem?> itemByCode(String value) {
    return (select(
      inventoryItems,
    )..where((row) => row.codeValue.equals(value))).getSingleOrNull();
  }

  Future<void> saveItem(InventoryItemsCompanion item) async {
    await into(inventoryItems).insertOnConflictUpdate(item);
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await (update(inventoryItems)..where((row) => row.id.equals(id))).write(
      InventoryItemsCompanion(
        isArchived: Value(archived),
        archivedAt: Value(archived ? DateTime.now().toUtc() : null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'lab_inventory.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
