import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/inventory_database.dart';
import 'services/export_service.dart';

final inventoryDatabaseProvider = Provider<InventoryDatabase>((ref) {
  final database = InventoryDatabase();
  ref.onDispose(database.close);
  return database;
});

final activeItemsProvider = StreamProvider<List<InventoryEntry>>((ref) {
  return ref.watch(inventoryDatabaseProvider).watchItems(archived: false);
});

final archivedItemsProvider = StreamProvider<List<InventoryEntry>>((ref) {
  return ref.watch(inventoryDatabaseProvider).watchItems(archived: true);
});

final itemProvider = FutureProvider.family<InventoryEntry?, String>((ref, id) {
  return ref.watch(inventoryDatabaseProvider).itemById(id);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(inventoryDatabaseProvider));
});
