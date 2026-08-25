import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory_enums.dart';
import '../../providers.dart';

class ArchivedItemsPage extends ConsumerWidget {
  const ArchivedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(archivedItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived items')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load archived items: $error')),
        data: (archived) {
          if (archived.isEmpty) {
            return const Center(child: Text('No archived items'));
          }
          return ListView.separated(
            itemCount: archived.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = archived[index];
              return ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(item.name),
                subtitle: Text('${item.itemType.label} · ${item.category}'),
                trailing: TextButton(
                  onPressed: () async {
                    await ref
                        .read(inventoryDatabaseProvider)
                        .setArchived(item.id, archived: false);
                    ref.invalidate(activeItemsProvider);
                  },
                  child: const Text('Restore'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
