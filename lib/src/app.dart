import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/inventory_enums.dart';
import 'features/inventory/archived_items_page.dart';
import 'features/inventory/inventory_home_page.dart';
import 'features/inventory/item_detail_page.dart';
import 'features/inventory/item_form_page.dart';
import 'features/scanner/scanner_page.dart';

class LabInventoryApp extends StatelessWidget {
  const LabInventoryApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const InventoryHomePage(),
      ),
      GoRoute(
        path: '/archive',
        builder: (context, state) => const ArchivedItemsPage(),
      ),
      GoRoute(
        path: '/item/new',
        builder: (context, state) {
          final codeTypeName = state.uri.queryParameters['codeType'];
          return ItemFormPage(
            scannedCode: state.uri.queryParameters['code'],
            scannedCodeType: ItemCodeType.values
                .where((type) => type.name == codeTypeName)
                .firstOrNull,
            package1P: state.uri.queryParameters['package1P'],
            package1PType: _codeType(
              state.uri.queryParameters['package1PType'],
            ),
            package1T: state.uri.queryParameters['package1T'],
            package1TType: _codeType(
              state.uri.queryParameters['package1TType'],
            ),
            packageMode: state.uri.queryParameters['packageMode'] == 'true',
          );
        },
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) =>
            ItemDetailPage(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/item/:id/edit',
        builder: (context, state) =>
            ItemFormPage(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/scan/:mode',
        builder: (context, state) => ScannerPage(
          mode: state.pathParameters['mode'] == 'create'
              ? ScanMode.create
              : ScanMode.find,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lab Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: _router,
    );
  }
}

ItemCodeType? _codeType(String? name) {
  return ItemCodeType.values.where((type) => type.name == name).firstOrNull;
}
