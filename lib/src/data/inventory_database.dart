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
  TextColumn get codeConfiguration => textEnum<ItemCodeConfiguration>()
      .withDefault(const Constant('itemOnly'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InventoryItemCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get role => textEnum<ItemCodeRole>()();
  TextColumn get codeType => textEnum<ItemCodeType>()();
  TextColumn get value => text().withLength(min: 1, max: 500).unique()();
  TextColumn get source => textEnum<ItemCodeSource>()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {itemId, role},
  ];
}

class InventoryEntry {
  const InventoryEntry({required this.item, required this.codes});

  final InventoryItem item;
  final List<InventoryItemCode> codes;

  InventoryItemCode? codeFor(ItemCodeRole role) {
    return codes.where((code) => code.role == role).firstOrNull;
  }
}

String normalizeCodeValue(String value) => value.trim();

@DriftDatabase(tables: [InventoryItems, InventoryItemCodes])
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase() : super(_openConnection());

  InventoryDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(inventoryItemCodes);
        await customStatement('''
          INSERT INTO inventory_item_codes
            (item_id, role, code_type, value, source)
          SELECT id, 'item', code_type, code_value, code_source
          FROM inventory_items
        ''');
        await migrator.alterTable(
          TableMigration(
            inventoryItems,
            columnTransformer: {
              inventoryItems.codeConfiguration: const Constant('itemOnly'),
            },
          ),
        );
      }
    },
  );

  Stream<List<InventoryEntry>> watchItems({required bool archived}) {
    final query =
        select(inventoryItems).join([
            leftOuterJoin(
              inventoryItemCodes,
              inventoryItemCodes.itemId.equalsExp(inventoryItems.id),
            ),
          ])
          ..where(inventoryItems.isArchived.equals(archived))
          ..orderBy([OrderingTerm.asc(inventoryItems.name)]);
    return query.watch().map(_groupEntries);
  }

  Future<List<InventoryEntry>> allItems() {
    final query = select(inventoryItems).join([
      leftOuterJoin(
        inventoryItemCodes,
        inventoryItemCodes.itemId.equalsExp(inventoryItems.id),
      ),
    ])..orderBy([OrderingTerm.asc(inventoryItems.name)]);
    return query.get().then(_groupEntries);
  }

  Future<InventoryEntry?> itemById(String id) async {
    final item = await (select(
      inventoryItems,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (item == null) return null;
    final codes = await (select(
      inventoryItemCodes,
    )..where((row) => row.itemId.equals(id))).get();
    return InventoryEntry(item: item, codes: codes);
  }

  Future<InventoryEntry?> itemByCode(String value) async {
    final normalized = normalizeCodeValue(value);
    if (normalized.isEmpty) return null;
    final code = await (select(
      inventoryItemCodes,
    )..where((row) => row.value.equals(normalized))).getSingleOrNull();
    return code == null ? null : itemById(code.itemId);
  }

  Future<void> saveItem(
    InventoryItemsCompanion item,
    List<InventoryItemCodesCompanion> codes,
  ) {
    return transaction(() async {
      await into(inventoryItems).insertOnConflictUpdate(item);
      final itemId = item.id.value;
      await (delete(
        inventoryItemCodes,
      )..where((row) => row.itemId.equals(itemId))).go();
      await batch((batch) => batch.insertAll(inventoryItemCodes, codes));
    });
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

  List<InventoryEntry> _groupEntries(List<TypedResult> rows) {
    final grouped = <String, InventoryEntry>{};
    for (final row in rows) {
      final item = row.readTable(inventoryItems);
      final entry = grouped.putIfAbsent(
        item.id,
        () => InventoryEntry(item: item, codes: []),
      );
      final code = row.readTableOrNull(inventoryItemCodes);
      if (code != null) entry.codes.add(code);
    }
    return grouped.values.toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'lab_inventory.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
