import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/inventory_database.dart';
import '../../domain/inventory_enums.dart';
import '../../providers.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key});

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(activeItemsProvider);
    final searchState = ref.watch(inventorySearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab inventory'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.exportJson,
                child: Text('Export JSON'),
              ),
              PopupMenuItem(
                value: _MenuAction.exportCsv,
                child: Text('Export CSV'),
              ),
              PopupMenuItem(
                value: _MenuAction.archive,
                child: Text('Archived items'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: 'Search name, category, serial, or code',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref
                  .read(inventorySearchProvider.notifier)
                  .setQuery(value.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: searchState.itemType == null,
                    onSelected: (_) => ref
                        .read(inventorySearchProvider.notifier)
                        .setItemType(null),
                  ),
                ),
                ...LabItemType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: searchState.itemType == type,
                      onSelected: (_) => ref
                          .read(inventorySearchProvider.notifier)
                          .setItemType(type),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ErrorView(error: error),
              data: (allItems) {
                final visible = allItems.where(_matchesSearch).toList();
                if (visible.isEmpty) {
                  return _EmptyInventory(hasFilters: allItems.isNotEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activeItemsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final inventoryItem = item.item;
                      final itemCode = item.codeFor(ItemCodeRole.item);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconFor(inventoryItem.itemType)),
                        ),
                        title: Text(inventoryItem.name),
                        subtitle: Text(
                          '${inventoryItem.itemType.label} · '
                          '${inventoryItem.category}\n'
                          '${itemCode?.codeType.label ?? 'Code'}: '
                          '${itemCode?.value ?? 'Missing'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/item/${inventoryItem.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            tooltip: 'Scan to find',
            onPressed: () => context.push('/scan/find'),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => context.push('/item/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(InventoryEntry entry) {
    final item = entry.item;
    final searchState = ref.read(inventorySearchProvider);

    if (searchState.itemType != null && item.itemType != searchState.itemType) {
      return false;
    }
    if (searchState.query.isEmpty) return true;
    return [
      item.name,
      item.category,
      item.serialNumber ?? '',
      ...entry.codes.map((code) => code.value),
    ].any((value) => value.toLowerCase().contains(searchState.query));
  }

  Future<void> _handleMenu(_MenuAction action) async {
    if (action == _MenuAction.archive) {
      await context.push('/archive');
      return;
    }
    try {
      final service = ref.read(exportServiceProvider);
      final file = action == _MenuAction.exportJson
          ? await service.exportJson()
          : await service.exportCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export saved to ${file.path}')));
      await service.share(file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }
}

enum _MenuAction { exportJson, exportCsv, archive }

IconData _iconFor(LabItemType type) => switch (type) {
  LabItemType.tool => Icons.handyman,
  LabItemType.equipment => Icons.precision_manufacturing,
  LabItemType.utility => Icons.inventory_2,
};

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching items' : 'No inventory items yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 8),
              const Text(
                'Add an item manually or scan an existing barcode or QR code.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/scan/create'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan new item'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Could not load inventory: $error'));
  }
}
