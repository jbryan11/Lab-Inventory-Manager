import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/inventory_database.dart';
import 'domain/inventory_enums.dart';
import 'services/export_service.dart';
import 'services/json_importer.dart';

final appLifecycleProvider =
    StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState?>(
      (ref) => AppLifecycleNotifier(),
    );

class AppLifecycleNotifier extends StateNotifier<AppLifecycleState?>
    with WidgetsBindingObserver {
  AppLifecycleNotifier() : super(WidgetsBinding.instance.lifecycleState) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

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
    required this.isExpanded,
  });

  const InventorySearchState.initial()
    : query = '',
      itemType = null,
      isExpanded = false;

  final String query;
  final LabItemType? itemType;
  final bool isExpanded;

  bool get hasFilters => query.trim().isNotEmpty || itemType != null;

  InventorySearchState copyWith({String? query, bool? isExpanded}) {
    return InventorySearchState(
      query: query ?? this.query,
      itemType: itemType,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  InventorySearchState withItemType(LabItemType? itemType) {
    return InventorySearchState(
      query: query,
      itemType: itemType,
      isExpanded: isExpanded,
    );
  }
}

final inventorySearchProvider =
    StateNotifierProvider<InventorySearchNotifier, InventorySearchState>(
      (ref) => InventorySearchNotifier(),
    );

class InventorySearchNotifier extends StateNotifier<InventorySearchState> {
  InventorySearchNotifier() : super(const InventorySearchState.initial());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setItemType(LabItemType type) {
    state = state.withItemType(type);
  }

  void clearItemType() {
    state = state.withItemType(null);
  }

  void openSearch() {
    state = state.copyWith(isExpanded: true);
  }

  void closeSearch() {
    state = state.copyWith(query: '', isExpanded: false);
  }

  void reset() {
    state = const InventorySearchState.initial();
  }
}

final filteredInventoryProvider = Provider<AsyncValue<List<InventoryEntry>>>((
  ref,
) {
  final search = ref.watch(inventorySearchProvider);
  final normalizedQuery = search.query.trim().toLowerCase();
  return ref
      .watch(activeItemsProvider)
      .whenData(
        (items) => items.where((entry) {
          if (search.itemType != null &&
              entry.item.itemType != search.itemType) {
            return false;
          }
          if (normalizedQuery.isEmpty) return true;
          return [
            entry.item.name,
            entry.item.category,
            entry.item.serialNumber ?? '',
            ...entry.codes.map((code) => code.value),
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
        }).toList(),
      );
});

final inventorySearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      // Durable query state lives in inventorySearchProvider. The controller is
      // recreated from it whenever the inventory page is remounted.
      final controller = TextEditingController(
        text: ref.read(inventorySearchProvider).query,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final inventorySearchFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final focusNode = FocusNode();
  ref.onDispose(focusNode.dispose);
  return focusNode;
});

final itemProvider = FutureProvider.family<InventoryEntry?, String>((ref, id) {
  return ref.watch(inventoryDatabaseProvider).itemById(id);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(inventoryDatabaseProvider));
});

final jsonImporterProvider = Provider<JsonImporter>((ref) {
  return JsonImporter(ref.watch(inventoryDatabaseProvider));
});
