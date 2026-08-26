import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/inventory_database.dart';
import 'domain/inventory_enums.dart';
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

/// State for inventory search/filtering.
class InventorySearchState {
  const InventorySearchState({
    required this.query,
    required this.itemType,
  });

  final String query;
  final LabItemType? itemType;

  InventorySearchState copyWith({
    String? query,
    LabItemType? itemType,
  }) {
    return InventorySearchState(
      query: query ?? this.query,
      itemType: itemType ?? this.itemType,
    );
  }
}

final inventorySearchProvider =
    StateNotifierProvider<InventorySearchNotifier, InventorySearchState>(
  (ref) => InventorySearchNotifier(),
);

class InventorySearchNotifier extends StateNotifier<InventorySearchState> {
  InventorySearchNotifier()
      : super(const InventorySearchState(query: '', itemType: null));

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setItemType(LabItemType? type) {
    state = state.copyWith(itemType: type);
  }

  void reset() {
    state = const InventorySearchState(query: '', itemType: null);
  }
}

final itemProvider = FutureProvider.family<InventoryEntry?, String>((ref, id) {
  return ref.watch(inventoryDatabaseProvider).itemById(id);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(inventoryDatabaseProvider));
});
