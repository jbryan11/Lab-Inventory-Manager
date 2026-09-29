import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/data/inventory_database.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/services/export_service.dart';
import 'package:lab_inventory_manager/src/services/json_importer.dart';

void main() {
  group('import/export integration', () {
    late InventoryDatabase source;
    late InventoryDatabase restored;
    late Directory temporaryDirectory;
    late Directory sourceDocuments;
    late Directory restoredDocuments;

    setUp(() async {
      source = InventoryDatabase.forTesting(NativeDatabase.memory());
      restored = InventoryDatabase.forTesting(NativeDatabase.memory());
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'inventory-roundtrip-',
      );
      sourceDocuments = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}source',
      );
      restoredDocuments = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}restored',
      );
    });

    tearDown(() async {
      await source.close();
      await restored.close();
      await temporaryDirectory.delete(recursive: true);
    });

    test('add, search, export, import restores all inventory data', () async {
      await source.saveItem(
        _item(
          id: 'meter-1',
          name: 'Precision, "bench" meter',
          type: LabItemType.equipment,
          category: '測試 equipment',
          serialNumber: 'SN-100',
          configuration: ItemCodeConfiguration.packageAndItem,
        ),
        [
          _code(
            itemId: 'meter-1',
            role: ItemCodeRole.item,
            type: ItemCodeType.code128,
            value: 'ITEM-100',
            source: ItemCodeSource.scanned,
          ),
          _code(
            itemId: 'meter-1',
            role: ItemCodeRole.package1P,
            type: ItemCodeType.qr,
            value: 'PACKAGE-1P',
            source: ItemCodeSource.generated,
          ),
          _code(
            itemId: 'meter-1',
            role: ItemCodeRole.package1T,
            type: ItemCodeType.dataMatrix,
            value: 'PACKAGE-1T',
            source: ItemCodeSource.scanned,
          ),
        ],
      );
      await source.saveItem(
        _item(
          id: 'tool-1',
          name: 'Archived wrench',
          type: LabItemType.tool,
          category: 'Hand tools',
          serialNumber: null,
        ),
        [
          _code(
            itemId: 'tool-1',
            role: ItemCodeRole.item,
            type: ItemCodeType.qr,
            value: 'TOOL-100',
            source: ItemCodeSource.generated,
          ),
        ],
      );
      await source.setArchived('tool-1', archived: true);

      final searchResults = await source.searchItems(
        archived: false,
        query: 'package-1t',
      );
      expect(searchResults.map((entry) => entry.item.id), ['meter-1']);

      final sourceExporter = ExportService(
        source,
        documentsDirectory: () async => sourceDocuments,
      );
      final jsonFile = await sourceExporter.exportJson();
      final sourceCsv = await sourceExporter.exportCsv();

      expect(await jsonFile.exists(), isTrue);
      expect(await sourceCsv.exists(), isTrue);

      final importer = JsonImporter(restored);
      final firstImport = await importer.importFromFile(jsonFile);
      final secondImport = await importer.importFromFile(jsonFile);

      expect(firstImport.success, isTrue);
      expect(firstImport.itemsImported, 2);
      expect(firstImport.codesImported, 4);
      expect(secondImport.success, isTrue);
      expect(await restored.allItems(), hasLength(2));

      await _expectEquivalent(source, restored);

      final restoredSearch = await restored.searchItems(
        archived: false,
        query: 'SN-100',
      );
      expect(restoredSearch.map((entry) => entry.item.id), ['meter-1']);
      expect(await restored.watchItems(archived: true).first, hasLength(1));

      final restoredExporter = ExportService(
        restored,
        documentsDirectory: () async => restoredDocuments,
      );
      final restoredCsv = await restoredExporter.exportCsv();
      expect(await restoredCsv.readAsString(), await sourceCsv.readAsString());
    });

    test(
      'conflicting import fails atomically and preserves existing data',
      () async {
        await source.saveItem(
          _item(
            id: 'valid',
            name: 'A valid item',
            type: LabItemType.equipment,
            category: 'Equipment',
          ),
          [
            _code(
              itemId: 'valid',
              role: ItemCodeRole.item,
              type: ItemCodeType.qr,
              value: 'VALID-CODE',
              source: ItemCodeSource.generated,
            ),
          ],
        );
        await source.saveItem(
          _item(
            id: 'incoming',
            name: 'Incoming item',
            type: LabItemType.utility,
            category: 'Utilities',
          ),
          [
            _code(
              itemId: 'incoming',
              role: ItemCodeRole.item,
              type: ItemCodeType.code128,
              value: 'SHARED-CODE',
              source: ItemCodeSource.scanned,
            ),
          ],
        );
        await restored.saveItem(
          _item(
            id: 'protected',
            name: 'Protected item',
            type: LabItemType.tool,
            category: 'Tools',
          ),
          [
            _code(
              itemId: 'protected',
              role: ItemCodeRole.item,
              type: ItemCodeType.code128,
              value: 'SHARED-CODE',
              source: ItemCodeSource.scanned,
            ),
          ],
        );
        final jsonFile = await ExportService(
          source,
          documentsDirectory: () async => sourceDocuments,
        ).exportJson();

        final result = await JsonImporter(restored).importFromFile(jsonFile);

        expect(result.success, isFalse);
        expect(result.itemsImported, 0);
        expect(result.codesImported, 0);
        expect(result.errors.single, contains('already belongs'));
        final remaining = await restored.allItems();
        expect(remaining, hasLength(1));
        expect(remaining.single.item.id, 'protected');
        expect(remaining.single.codes.single.value, 'SHARED-CODE');
        expect(await restored.itemById('valid'), isNull);
        expect(await restored.itemById('incoming'), isNull);
      },
    );

    test(
      'malformed import leaves the destination database unchanged',
      () async {
        await restored.saveItem(
          _item(
            id: 'protected',
            name: 'Protected item',
            type: LabItemType.tool,
            category: 'Tools',
          ),
          [
            _code(
              itemId: 'protected',
              role: ItemCodeRole.item,
              type: ItemCodeType.qr,
              value: 'PROTECTED-100',
              source: ItemCodeSource.generated,
            ),
          ],
        );
        final malformed = File(
          '${temporaryDirectory.path}${Platform.pathSeparator}malformed.json',
        );
        await malformed.writeAsString('{"items": [');

        final result = await JsonImporter(restored).importFromFile(malformed);

        expect(result.success, isFalse);
        final remaining = await restored.allItems();
        expect(remaining, hasLength(1));
        expect(remaining.single.item.id, 'protected');
      },
    );
  });
}

Future<void> _expectEquivalent(
  InventoryDatabase expectedDatabase,
  InventoryDatabase actualDatabase,
) async {
  final expected = {
    for (final entry in await expectedDatabase.allItems()) entry.item.id: entry,
  };
  final actual = {
    for (final entry in await actualDatabase.allItems()) entry.item.id: entry,
  };
  expect(actual.keys, unorderedEquals(expected.keys));

  for (final id in expected.keys) {
    final expectedEntry = expected[id]!;
    final actualEntry = actual[id]!;
    expect(actualEntry.item.name, expectedEntry.item.name);
    expect(actualEntry.item.itemType, expectedEntry.item.itemType);
    expect(actualEntry.item.category, expectedEntry.item.category);
    expect(actualEntry.item.serialNumber, expectedEntry.item.serialNumber);
    expect(
      actualEntry.item.codeConfiguration,
      expectedEntry.item.codeConfiguration,
    );
    expect(actualEntry.item.createdAt, expectedEntry.item.createdAt);
    expect(actualEntry.item.updatedAt, expectedEntry.item.updatedAt);
    expect(actualEntry.item.isArchived, expectedEntry.item.isArchived);
    expect(actualEntry.item.archivedAt, expectedEntry.item.archivedAt);
    expect(
      actualEntry.codes.map(_codeSignature),
      unorderedEquals(expectedEntry.codes.map(_codeSignature)),
    );
  }
}

String _codeSignature(InventoryItemCode code) {
  return '${code.role.name}|${code.codeType.name}|${code.value}|'
      '${code.source.name}';
}

InventoryItemsCompanion _item({
  required String id,
  required String name,
  required LabItemType type,
  required String category,
  String? serialNumber,
  ItemCodeConfiguration configuration = ItemCodeConfiguration.itemOnly,
}) {
  final createdAt = DateTime.utc(2026, 9, 28, 8, 30);
  return InventoryItemsCompanion(
    id: Value(id),
    name: Value(name),
    itemType: Value(type),
    category: Value(category),
    serialNumber: Value(serialNumber),
    codeConfiguration: Value(configuration),
    createdAt: Value(createdAt),
    updatedAt: Value(createdAt.add(const Duration(hours: 1))),
  );
}

InventoryItemCodesCompanion _code({
  required String itemId,
  required ItemCodeRole role,
  required ItemCodeType type,
  required String value,
  required ItemCodeSource source,
}) {
  return InventoryItemCodesCompanion.insert(
    itemId: itemId,
    role: role,
    codeType: type,
    value: value,
    source: source,
  );
}
