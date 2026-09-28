import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';
  LabItemType? _type;
  bool _searchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(activeItemsProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _searchExpanded
            ? SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search inventory',
                leading: const Icon(Icons.search),
                trailing: [
                  IconButton(
                    tooltip: 'Close search',
                    onPressed: _closeSearch,
                    icon: const Icon(Icons.close),
                  ),
                ],
                onChanged: _updateQuery,
              )
            : Row(
                children: [
                  const Expanded(child: Text('Lab inventory')),
                  IconButton(
                    tooltip: 'Search inventory',
                    onPressed: _openSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
      ),
      drawer: _InventoryDrawer(onMenuSelected: _handleMenu),
      body: Column(
        children: [
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
                    selected: _type == null,
                    onSelected: (_) => setState(() => _type = null),
                  ),
                ),
                ...LabItemType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
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
                final visible = allItems.where(_matches).toList();
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
                      final entry = visible[index];
                      final item = entry.item;
                      final code = entry.codeFor(ItemCodeRole.item);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconFor(item.itemType)),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.itemType.label} · ${item.category}\n'
                          '${code?.codeType.label ?? 'Unknown'}: ${code?.value ?? 'N/A'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/item/${item.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan to find',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            label: 'New item',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
        onDestinationSelected: _handleNavigation,
      ),
    );
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _query = '';
      _searchExpanded = false;
    });
  }

  void _updateQuery(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
      case 1:
        _searchController.clear();
        setState(() {
          _query = '';
          _type = null;
          _searchExpanded = false;
        });
        return;
      case 2:
        context.push('/scan/find');
        return;
      case 3:
        context.push('/item/new');
        return;
      case 4:
        _showMoreMenu();
        return;
    }
  }

  Future<void> _showMoreMenu() async {
    final box = context.findRenderObject()! as RenderBox;
    final action = await showMenu<_MenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        box.size.width - 16,
        box.size.height - 80,
        16,
        80,
      ),
      items: const [
        PopupMenuItem(
          value: _MenuAction.importJson,
          child: Text('Import JSON'),
        ),
        PopupMenuItem(
          value: _MenuAction.exportJson,
          child: Text('Export JSON'),
        ),
        PopupMenuItem(value: _MenuAction.exportCsv, child: Text('Export CSV')),
        PopupMenuItem(
          value: _MenuAction.archive,
          child: Text('Archived items'),
        ),
      ],
    );
    if (action != null) await _handleMenu(action);
  }

  bool _matches(InventoryEntry entry) {
    if (_type != null && entry.item.itemType != _type) return false;
    if (_query.isEmpty) return true;
    final codeValue = entry.codeFor(ItemCodeRole.item)?.value ?? '';
    return [
      entry.item.name,
      entry.item.category,
      entry.item.serialNumber ?? '',
      codeValue,
    ].any((value) => value.toLowerCase().contains(_query));
  }

  Future<void> _handleMenu(_MenuAction action) async {
    if (action == _MenuAction.archive) {
      await context.push('/archive');
      return;
    }
    if (action == _MenuAction.importJson) {
      await _importJson();
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

  Future<void> _importJson() async {
    final selection = await _pickJsonFile();
    final path = selection?.path;
    if (path == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Importing inventory...')),
            ],
          ),
        ),
      ),
    );

    final result = await ref
        .read(jsonImporterProvider)
        .importFromFile(File(path));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final message = result.success
        ? 'Imported ${result.itemsImported} items and '
              '${result.codesImported} codes.'
        : result.errors.length == 1
        ? 'Import failed: ${result.errors.first}'
        : 'Import failed with ${result.errors.length} errors: '
              '${result.errors.first}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result.success
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<PlatformFile?> _pickJsonFile() async {
    try {
      return await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file picker: $error')),
        );
      }
      return null;
    }
  }
}

enum _MenuAction { importJson, exportJson, exportCsv, archive }

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

class _InventoryDrawer extends StatelessWidget {
  const _InventoryDrawer({required this.onMenuSelected});

  final ValueChanged<_MenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 28, 16, 16),
          child: Text('Lab inventory'),
        ),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('Home'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Inventory'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner),
          title: const Text('Scan to find'),
          onTap: () {
            Navigator.pop(context);
            context.push('/scan/find');
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_box_outlined),
          title: const Text('New inventory item'),
          onTap: () {
            Navigator.pop(context);
            context.push('/item/new');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Import JSON'),
          onTap: () {
            Navigator.pop(context);
            onMenuSelected(_MenuAction.importJson);
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Archived items'),
          onTap: () {
            Navigator.pop(context);
            onMenuSelected(_MenuAction.archive);
          },
        ),
      ],
    );
  }
}
