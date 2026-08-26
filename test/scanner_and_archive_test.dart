import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/features/scanner/barcode_classifier.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('BarcodeClassifier', () {
    test('classifies barcodes with embedded role classifiers', () {
      // GS1-128 classifiers: (01) for 1P, (21) for 1T
      final barcodes = [
        MockBarcode(rawValue: '(01)12345', format: BarcodeFormat.code128),
        MockBarcode(rawValue: '(21)67890', format: BarcodeFormat.code128),
      ];
      final capture = MockBarcodeCapture(barcodes: barcodes);

      final classified = BarcodeClassifier.classify(capture);

      expect(classified.length, 2);
      expect(
        classified.where((c) => c.role == ItemCodeRole.package1P).length,
        1,
      );
      expect(
        classified.where((c) => c.role == ItemCodeRole.package1T).length,
        1,
      );
    });

    test('assigns 1P/1T roles by vertical position for unclassified codes', () {
      final barcodes = [
        MockBarcode(
          rawValue: 'CODE-TOP',
          format: BarcodeFormat.code128,
          corners: const [Offset(0, 50), Offset(100, 50)],
        ),
        MockBarcode(
          rawValue: 'CODE-BOTTOM',
          format: BarcodeFormat.code128,
          corners: const [Offset(0, 200), Offset(100, 200)],
        ),
      ];
      final capture = MockBarcodeCapture(barcodes: barcodes);
      final classified = BarcodeClassifier.classify(capture);
      final unclassified = classified
          .where((c) => c.role == null)
          .toList();

      final assigned = BarcodeClassifier.assignPackageRolesByPosition(unclassified);

      expect(assigned, isNotNull);
      expect(assigned!.package1P.parsed!.value, 'CODE-TOP');
      expect(assigned.package1T.parsed!.value, 'CODE-BOTTOM');
    });

    test('returns null when fewer than 2 unclassified barcodes for position assignment',
        () {
      final barcodes = [
        MockBarcode(rawValue: 'SINGLE', format: BarcodeFormat.qrCode),
      ];
      final capture = MockBarcodeCapture(barcodes: barcodes);
      final classified = BarcodeClassifier.classify(capture);
      final unclassified = classified
          .where((c) => c.role == null)
          .toList();

      final assigned = BarcodeClassifier.assignPackageRolesByPosition(unclassified);

      expect(assigned, isNull);
    });

    test('resolves mixed roles (classifier + position)', () {
      final classified1P = ClassifiedBarcode(
        barcode: MockBarcode(rawValue: '(01)PACKAGE1P', format: BarcodeFormat.code128),
        parsed: ParsedCode(role: ItemCodeRole.package1P, value: 'PACKAGE1P'),
        role: ItemCodeRole.package1P,
      );
      final unclassified = [
        ClassifiedBarcode(
          barcode: MockBarcode(rawValue: 'UNCLASSIFIED', format: BarcodeFormat.code128),
          parsed: ParsedCode(role: null, value: 'UNCLASSIFIED'),
          role: null,
        ),
      ];

      final resolved = BarcodeClassifier.resolveMixedRoles(
        classified1P,
        null,
        unclassified,
      );

      expect(resolved, isNotNull);
      expect(resolved!.package1P.role, ItemCodeRole.package1P);
      expect(resolved.package1T.parsed!.value, 'UNCLASSIFIED');
    });
  });

  group('Archive and Restore', () {
    late InventoryDatabase database;

    setUp(() {
      database = InventoryDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('archives item and prevents duplicate codes on new items', () async {
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'CODE-001'),
      ]);

      await database.setArchived('item-1', archived: true);
      expect(
        await database.watchItems(archived: false).first,
        isEmpty,
      );
      expect(
        await database.watchItems(archived: true).first,
        hasLength(1),
      );

      // Code is still reserved for archived item
      expect(
        () => database.saveItem(_item(id: 'item-2'), [
          _code(itemId: 'item-2', value: 'CODE-001'),
        ]),
        throwsA(isA<SqliteException>()),
      );
    });

    test('restores archived item to active inventory', () async {
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'CODE-001'),
      ]);
      await database.setArchived('item-1', archived: true);

      await database.setArchived('item-1', archived: false);

      expect(
        await database.watchItems(archived: false).first,
        hasLength(1),
      );
      expect(
        await database.watchItems(archived: true).first,
        isEmpty,
      );
    });

    test('tracks archived timestamp when archiving', () async {
      final now = DateTime.utc(2026, 8, 26);
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'CODE-001'),
      ]);

      await database.setArchived('item-1', archived: true);

      final archived = await database.watchItems(archived: true).first;
      expect(archived.first.item.archivedAt, isNotNull);
      expect(archived.first.item.archivedAt!.isAfter(now), true);
    });

    test('clears archived timestamp when restoring', () async {
      await database.saveItem(_item(id: 'item-1'), [
        _code(itemId: 'item-1', value: 'CODE-001'),
      ]);
      await database.setArchived('item-1', archived: true);

      await database.setArchived('item-1', archived: false);

      final active = await database.watchItems(archived: false).first;
      expect(active.first.item.archivedAt, isNull);
    });
  });
}

// Mocks and helpers

class MockBarcode implements Barcode {
  MockBarcode({
    required this.rawValue,
    required this.format,
    this.corners = const [],
  });

  @override
  final String? rawValue;
  @override
  final BarcodeFormat format;
  @override
  final List<Offset> corners;

  @override
  String? get displayValue => rawValue;

  @override
  int? get height => null;
  @override
  int? get left => null;
  @override
  int? get top => null;
  @override
  int? get width => null;
}

class MockBarcodeCapture implements BarcodeCapture {
  MockBarcodeCapture({required this.barcodes});

  @override
  final List<Barcode> barcodes;

  @override
  int? get height => null;
  @override
  int? get width => null;
}

InventoryItemsCompanion _item({
  required String id,
  ItemCodeConfiguration configuration = ItemCodeConfiguration.itemOnly,
}) {
  final now = DateTime.utc(2026, 8, 25);
  return InventoryItemsCompanion(
    id: Value(id),
    name: const Value('Test item'),
    itemType: const Value(LabItemType.equipment),
    category: const Value('Test'),
    serialNumber: const Value('SN-001'),
    codeConfiguration: Value(configuration),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}

InventoryItemCodesCompanion _code({
  required String itemId,
  required String value,
  ItemCodeRole role = ItemCodeRole.item,
}) {
  return InventoryItemCodesCompanion.insert(
    itemId: itemId,
    role: role,
    codeType: ItemCodeType.code128,
    value: value,
    source: ItemCodeSource.scanned,
  );
}

class ParsedCode {
  ParsedCode({required this.role, required this.value});
  final ItemCodeRole? role;
  final String value;
}
