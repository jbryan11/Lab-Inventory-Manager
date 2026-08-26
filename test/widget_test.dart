import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/app.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/features/inventory/item_form_page.dart';
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

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.text('New inventory item'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    final formSafeArea = tester
        .widgetList<SafeArea>(find.byType(SafeArea))
        .where((safeArea) => !safeArea.top && safeArea.bottom);
    expect(formSafeArea, hasLength(1));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Lab inventory'), findsOneWidget);
  });

  testWidgets('shows all package and item code fields in package mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ItemFormPage(packageMode: true)),
      ),
    );
    await tester.pumpAndSettle();

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
