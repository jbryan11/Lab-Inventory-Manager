import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
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
    onCreate: (migrator) async {
      try {
        AppLogger.info('Creating database schema...');
        await migrator.createAll();
        AppLogger.info('Database schema created successfully');
      } catch (e, st) {
        AppLogger.error('Failed to create database schema', e, st);
        throw MigrationException(
          'Failed to create database schema: $e',
          originalError: e,
          stackTrace: st,
        );
      }
    },
    onUpgrade: (migrator, from, to) async {
      try {
        AppLogger.info('Migrating database from v$from to v$to...');
        if (from < 2) {
          // Step 1: Validate old schema
          AppLogger.debug('Validating old schema before migration...');
          final oldItems = await customSelect(
            'SELECT id, code_type, code_value, code_source FROM inventory_items LIMIT 1',
          ).get();
          AppLogger.debug('Old schema validation passed');

          // Step 2: Create new table
          AppLogger.debug('Creating inventory_item_codes table...');
          await migrator.createTable(inventoryItemCodes);

          // Step 3: Migrate data with error handling
          AppLogger.debug('Migrating item codes...');
          await customStatement('''
            INSERT INTO inventory_item_codes
              (item_id, role, code_type, value, source)
            SELECT id, 'item', code_type, code_value, code_source
            FROM inventory_items
          ''');

          // Step 4: Verify migration
          final migratedCount = await customSelect(
            'SELECT COUNT(*) as cnt FROM inventory_item_codes',
          ).get();
          AppLogger.debug('Migrated ${migratedCount.first.data['cnt']} codes');

          // Step 5: Alter original table
          AppLogger.debug('Altering inventory_items table...');
          await migrator.alterTable(
            TableMigration(
              inventoryItems,
              columnTransformer: {
                inventoryItems.codeConfiguration: const Constant('itemOnly'),
              },
            ),
          );
        }
        AppLogger.info('Database migration completed successfully');
      } on MigrationException {
        rethrow;
      } catch (e, st) {
        AppLogger.error('Database migration failed', e, st);
        throw MigrationException(
          'Failed to migrate database from v$from to v$to: $e',
          originalError: e,
          stackTrace: st,
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

  /// Searches items by name, category, serial, or code.
  ///
  /// Returns all items matching the search query and optional type filter.
  /// Query is case-insensitive and searched in name, category, serial number,
  /// and all code values.
  Future<List<InventoryEntry>> searchItems({
    required bool archived,
    required String query,
    ItemCodeType? codeType,
  }) async {
    if (query.isEmpty && codeType == null) {
      return watchItems(archived: archived).first;
    }

    final entries = await watchItems(archived: archived).first;
    final normalized = query.toLowerCase();

    return entries.where((entry) {
      final item = entry.item;

      // Filter by type if specified
      if (codeType != null) {
        if (item.itemType.name != codeType.name) return false;
      }

      // Match query in any field
      if (normalized.isEmpty) return true;

      return [
        item.name,
        item.category,
        item.serialNumber ?? '',
        ...entry.codes.map((code) => code.value),
      ].any((value) => value.toLowerCase().contains(normalized));
    }).toList();
  }

  Future<InventoryEntry?> itemById(String id) async {
    try {
      AppLogger.debug('Fetching item by ID: $id');
      final item = await (select(
        inventoryItems,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (item == null) {
        AppLogger.debug('Item not found: $id');
        return null;
      }
      final codes = await (select(
        inventoryItemCodes,
      )..where((row) => row.itemId.equals(id))).get();
      AppLogger.debug('Found item $id with ${codes.length} codes');
      return InventoryEntry(item: item, codes: codes);
    } catch (e, st) {
      AppLogger.error('Failed to fetch item $id', e, st);
      throw DatabaseException(
        'Failed to fetch item: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<InventoryEntry?> itemByCode(String value) async {
    try {
      final normalized = normalizeCodeValue(value);
      if (normalized.isEmpty) {
        AppLogger.warning('Attempted to search with empty code value');
        return null;
      }
      AppLogger.debug('Searching for item by code: $normalized');
      final code = await (select(
        inventoryItemCodes,
      )..where((row) => row.value.equals(normalized))).getSingleOrNull();
      if (code == null) {
        AppLogger.debug('No item found with code: $normalized');
        return null;
      }
      return itemById(code.itemId);
    } catch (e, st) {
      AppLogger.error('Failed to search item by code', e, st);
      throw DatabaseException(
        'Failed to search item by code: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> saveItem(
    InventoryItemsCompanion item,
    List<InventoryItemCodesCompanion> codes,
  ) async {
    try {
      final itemId = item.id.value;
      AppLogger.info('Saving item $itemId with ${codes.length} code(s)');
      
      await transaction(() async {
        try {
          // Save/update item
          await into(inventoryItems).insertOnConflictUpdate(item);
          AppLogger.debug('Item $itemId saved successfully');
          
          // Delete old codes
          await (delete(
            inventoryItemCodes,
          )..where((row) => row.itemId.equals(itemId))).go();
          AppLogger.debug('Old codes for item $itemId deleted');
          
          // Insert new codes
          await batch((batch) => batch.insertAll(inventoryItemCodes, codes));
          AppLogger.info('Item $itemId and codes saved successfully');
        } catch (e, st) {
          AppLogger.error('Transaction failed for item $itemId', e, st);
          rethrow;
        }
      });
    } catch (e, st) {
      AppLogger.error('Failed to save item', e, st);
      throw DatabaseException(
        'Failed to save item: $e',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    try {
      AppLogger.info('Setting item $id archive status to $archived');
      await (update(inventoryItems)..where((row) => row.id.equals(id))).write(
        InventoryItemsCompanion(
          isArchived: Value(archived),
          archivedAt: Value(archived ? DateTime.now().toUtc() : null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      AppLogger.info('Item $id archive status updated successfully');
    } catch (e, st) {
      AppLogger.error('Failed to set archive status for item $id', e, st);
      throw DatabaseException(
        'Failed to set archive status: $e',
        originalError: e,
        stackTrace: st,
      );
    }
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
