import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/app.dart';
import 'package:lab_inventory_manager/src/providers.dart';

void main() {
  testWidgets('shows the empty inventory actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const LabInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lab inventory'), findsOneWidget);
    expect(find.text('No inventory items yet'), findsOneWidget);
    expect(find.text('Scan new item'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
  });
}
