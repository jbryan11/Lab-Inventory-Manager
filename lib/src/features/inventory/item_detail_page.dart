import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/inventory_database.dart';
import '../../domain/inventory_enums.dart';
import '../../providers.dart';
import '../../widgets/home_back_button.dart';
import 'item_label.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  final _labelKey = GlobalKey();
  bool _savingLabel = false;

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemProvider(widget.itemId));
    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: const Text('Item details'),
        actions: [
          IconButton(
            tooltip: 'Edit item',
            onPressed: () async {
              await context.push('/item/${widget.itemId}/edit');
              ref.invalidate(itemProvider(widget.itemId));
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: item.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load item: $error')),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('Item not found'));
          }
          return _buildDetails(value);
        },
      ),
    );
  }

  Widget _buildDetails(InventoryEntry entry) {
    final item = entry.item;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _DetailRow(label: 'Type', value: item.itemType.label),
        _DetailRow(label: 'Category', value: item.category),
        if (item.serialNumber != null)
          _DetailRow(label: 'Serial number', value: item.serialNumber!),
        _DetailRow(label: 'Code setup', value: item.codeConfiguration.label),
        ...entry.codes.map(
          (code) => _DetailRow(
            label: code.role.label,
            value: '${code.value} (${code.codeType.label})',
          ),
        ),
        const SizedBox(height: 24),
        Text('Printable label', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            key: _labelKey,
            child: ItemLabel(item: entry),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _savingLabel ? null : () => _saveLabel(entry),
          icon: const Icon(Icons.image_outlined),
          label: Text(_savingLabel ? 'Saving...' : 'Save / share label image'),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _archive(entry),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archive item'),
        ),
      ],
    );
  }

  Future<void> _saveLabel(InventoryEntry entry) async {
    final item = entry.item;
    setState(() => _savingLabel = true);
    try {
      final boundary =
          _labelKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not render label image.');
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory(p.join(documents.path, 'labels'));
      await directory.create(recursive: true);
      final file = File(p.join(directory.path, '${item.id}.png'));
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Label saved to ${file.path}')));
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save label: $error')));
    } finally {
      if (mounted) setState(() => _savingLabel = false);
    }
  }

  Future<void> _archive(InventoryEntry entry) async {
    final item = entry.item;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this item?'),
        content: Text(
          '${item.name} will leave the active inventory. Its code remains '
          'reserved and the item can be restored later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(inventoryDatabaseProvider)
        .setArchived(item.id, archived: true);
    ref.invalidate(activeItemsProvider);
    ref.invalidate(archivedItemsProvider);
    if (mounted) context.go('/');
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
