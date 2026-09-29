import 'package:barcode_widget/barcode_widget.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/features/inventory/item_form_page.dart';
import 'package:lab_inventory_manager/src/providers.dart';

void main() {
  group('ItemFormPage validation', () {
    late InventoryDatabase database;

    setUp(() {
      database = InventoryDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    testWidgets('shows field-specific errors for required values', (
      tester,
    ) async {
      await _pumpForm(tester, database);

      await tester.ensureVisible(find.byKey(const Key('save-button')));
      await tester.tap(find.byKey(const Key('save-button')));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Category is required'), findsOneWidget);
      expect(find.text('Code is required'), findsOneWidget);
      expect(await database.allItems(), isEmpty);
      await _disposeForm(tester);
    });

    testWidgets('saves valid form data and navigates to the item', (
      tester,
    ) async {
      await _pumpForm(tester, database);

      await tester.enterText(
        find.byKey(const Key('name-field')),
        'Bench meter',
      );
      await tester.enterText(
        find.byKey(const Key('category-field')),
        'Test equipment',
      );
      await tester.enterText(find.byKey(const Key('serial-field')), 'SN-100');
      await tester.enterText(find.byKey(const Key('code-field')), 'ITEM-100');
      await tester.ensureVisible(find.byKey(const Key('save-button')));
      await tester.tap(find.byKey(const Key('save-button')));
      await tester.pumpAndSettle();

      expect(find.text('Saved item'), findsOneWidget);
      final items = await database.allItems();
      expect(items, hasLength(1));
      expect(items.single.item.name, 'Bench meter');
      expect(items.single.item.serialNumber, 'SN-100');
      expect(items.single.codeFor(ItemCodeRole.item)?.value, 'ITEM-100');
      await _disposeForm(tester);
    });

    testWidgets('reports a duplicate code without creating an item', (
      tester,
    ) async {
      await database.saveItem(_item(id: 'existing'), [
        _code(itemId: 'existing', value: 'DUPLICATE'),
      ]);
      await _pumpForm(tester, database);

      await tester.enterText(find.byKey(const Key('name-field')), 'New item');
      await tester.enterText(find.byKey(const Key('category-field')), 'Test');
      await tester.enterText(find.byKey(const Key('code-field')), 'DUPLICATE');
      await tester.ensureVisible(find.byKey(const Key('save-button')));
      await tester.tap(find.byKey(const Key('save-button')));
      await tester.pumpAndSettle();

      expect(find.text('This code belongs to Existing item.'), findsOneWidget);
      expect(await database.allItems(), hasLength(1));
      await _disposeForm(tester);
    });

    testWidgets('shows detailed validation errors from InventoryValidator', (
      tester,
    ) async {
      await _pumpForm(tester, database);

      await tester.enterText(
        find.byKey(const Key('name-field')),
        List.filled(201, 'x').join(),
      );
      await tester.enterText(find.byKey(const Key('category-field')), 'Test');
      await tester.enterText(find.byKey(const Key('code-field')), 'ITEM-200');
      await tester.tap(find.byKey(const Key('save-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Item name must not exceed 200 characters'),
        findsOneWidget,
      );
      expect(await database.allItems(), isEmpty);
      await _disposeForm(tester);
    });

    testWidgets('initializes a scanned code and renders its preview', (
      tester,
    ) async {
      await _pumpForm(
        tester,
        database,
        form: const ItemFormPage(
          scannedCode: 'SCANNED-100',
          scannedCodeType: ItemCodeType.code128,
        ),
      );

      final codeField = tester.widget<TextFormField>(
        find.byKey(const Key('code-field')),
      );
      expect(codeField.controller?.text, 'SCANNED-100');
      expect(find.byType(BarcodeWidget), findsOneWidget);
      await _disposeForm(tester);
    });

    testWidgets('switches between generated and existing code sources', (
      tester,
    ) async {
      await _pumpForm(tester, database);

      await tester.tap(find.text('Generate'));
      await tester.pump();
      var codeField = tester.widget<TextFormField>(
        find.byKey(const Key('code-field')),
      );
      expect(codeField.controller?.text, isNotEmpty);

      await tester.tap(find.text('Existing'));
      await tester.pump();
      codeField = tester.widget<TextFormField>(
        find.byKey(const Key('code-field')),
      );
      expect(codeField.controller?.text, isEmpty);
      await _disposeForm(tester);
    });

    testWidgets('loads an existing item for editing', (tester) async {
      await database.saveItem(_item(id: 'existing'), [
        _code(itemId: 'existing', value: 'EXISTING-100'),
      ]);

      await _pumpForm(
        tester,
        database,
        form: const ItemFormPage(itemId: 'existing'),
      );

      expect(find.text('Edit item'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('name-field')))
            .controller
            ?.text,
        'Existing item',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('code-field')))
            .controller
            ?.text,
        'EXISTING-100',
      );
      await _disposeForm(tester);
    });
  });
}

Future<void> _pumpForm(
  WidgetTester tester,
  InventoryDatabase database, {
  ItemFormPage form = const ItemFormPage(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => form),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Saved item'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [inventoryDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _disposeForm(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

InventoryItemsCompanion _item({required String id}) {
  final now = DateTime.utc(2026, 9, 28);
  return InventoryItemsCompanion(
    id: Value(id),
    name: const Value('Existing item'),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test equipment'),
    codeConfiguration: const Value(ItemCodeConfiguration.itemOnly),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}

InventoryItemCodesCompanion _code({
  required String itemId,
  required String value,
}) {
  return InventoryItemCodesCompanion.insert(
    itemId: itemId,
    role: ItemCodeRole.item,
    codeType: ItemCodeType.code128,
    value: value,
    source: ItemCodeSource.scanned,
  );
}
