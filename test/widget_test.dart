import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/app.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
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

  testWidgets('shows a preview for a generated code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ItemFormPage(packageMode: true)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Generate'));
    await tester.tap(find.text('Generate'));
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text(ItemCodeConfiguration.packageAndItem.label),
      findsOneWidget,
    );
    expect(find.text('Package 1P value'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Package 1T value'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Barcode / QR value'), findsOneWidget);
  });
}
