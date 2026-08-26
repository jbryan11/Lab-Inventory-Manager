import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory_enums.dart';
import '../../providers.dart';
import '../../widgets/home_back_button.dart';

class ArchivedItemsPage extends ConsumerWidget {
  const ArchivedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(archivedItemsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: const Text('Archived items'),
      ),
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
              final inventoryItem = item.item;
              return ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(inventoryItem.name),
                subtitle: Text(
                  '${inventoryItem.itemType.label} · ${inventoryItem.category}',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await ref
                        .read(inventoryDatabaseProvider)
                        .setArchived(inventoryItem.id, archived: false);
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
