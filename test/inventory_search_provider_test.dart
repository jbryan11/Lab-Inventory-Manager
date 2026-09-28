import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/providers.dart';

void main() {
  group('inventory search providers', () {
    test('stores queries and clears nullable type filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(inventorySearchProvider.notifier);

      notifier.setQuery('  BENCH  ');
      notifier.setItemType(LabItemType.equipment);

      expect(container.read(inventorySearchProvider).query, '  BENCH  ');
      expect(
        container.read(inventorySearchProvider).itemType,
        LabItemType.equipment,
      );

      notifier.clearItemType();

      expect(container.read(inventorySearchProvider).itemType, isNull);
      expect(container.read(inventorySearchProvider).query, '  BENCH  ');
    });

    test('filters by type and any inventory code', () async {
      final entries = [
        _entry(
          id: 'meter',
          name: 'Bench meter',
          type: LabItemType.equipment,
          code: 'EQ-100',
        ),
        _entry(
          id: 'pliers',
          name: 'Pliers',
          type: LabItemType.tool,
          code: 'TOOL-200',
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(entries)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeItemsProvider.future);

      final notifier = container.read(inventorySearchProvider.notifier);
      notifier.setQuery('  TOOL-200  ');
      notifier.setItemType(LabItemType.tool);

      final filtered = container.read(filteredInventoryProvider).asData?.value;
      expect(filtered?.map((entry) => entry.item.id), ['pliers']);
    });

    test('retains search state while the provider scope is alive', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventorySearchProvider.notifier)
        ..openSearch()
        ..setQuery('persistent');

      expect(
        container.read(inventorySearchProvider),
        isA<InventorySearchState>()
            .having((state) => state.isExpanded, 'isExpanded', isTrue)
            .having((state) => state.query, 'query', 'persistent'),
      );
    });
  });
}

InventoryEntry _entry({
  required String id,
  required String name,
  required LabItemType type,
  required String code,
}) {
  final now = DateTime.utc(2026, 9, 28);
  return InventoryEntry(
    item: InventoryItem(
      id: id,
      name: name,
      itemType: type,
      category: 'Test',
      codeConfiguration: ItemCodeConfiguration.itemOnly,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
    ),
    codes: [
      InventoryItemCode(
        id: 1,
        itemId: id,
        role: ItemCodeRole.item,
        codeType: ItemCodeType.code128,
        value: code,
        source: ItemCodeSource.scanned,
      ),
    ],
  );
}
