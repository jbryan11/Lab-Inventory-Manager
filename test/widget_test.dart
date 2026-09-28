import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/app.dart';
import 'package:lab_inventory_manager/src/features/inventory/inventory_home_page.dart';
import 'package:lab_inventory_manager/src/features/inventory/item_form_page.dart';
import 'package:lab_inventory_manager/src/providers.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Scan to find'), findsOneWidget);
    expect(find.text('New item'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('expands search in the app bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const LabInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search inventory'));
    await tester.pump();

    expect(find.text('Search inventory'), findsOneWidget);
    expect(find.byTooltip('Close search'), findsOneWidget);
  });

  testWidgets('keeps inventory search state when the page is rebuilt', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);

    Widget app(Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    );

    await tester.pumpWidget(app(const InventoryHomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search inventory'));
    await tester.pump();
    await tester.enterText(find.byType(SearchBar), 'meter');
    await tester.pump();

    await tester.pumpWidget(app(const SizedBox()));
    await tester.pump();
    await tester.pumpWidget(app(const InventoryHomePage()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close search'), findsOneWidget);
    expect(find.text('meter'), findsOneWidget);
  });

  testWidgets('shows JSON import in the inventory menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const LabInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Import JSON'), findsOneWidget);
  });

  testWidgets('shows a preview for a generated code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ItemFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Generate'));
    await tester.tap(find.text('Generate'));
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
  });
}
