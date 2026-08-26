import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/inventory_database.dart';
import '../domain/inventory_enums.dart';

class ExportService {
  ExportService(this._database);

  final InventoryDatabase _database;

  Future<File> exportJson() async {
    final items = await _database.allItems();
    final payload = <String, Object?>{
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items.map(_itemToJson).toList(),
    };
    return _writeExport(
      'lab-inventory-${_timestamp()}.json',
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  Future<File> exportCsv() async {
    final items = await _database.allItems();
    final rows = <List<Object?>>[
      [
        'id',
        'name',
        'itemType',
        'category',
        'serialNumber',
        'codeConfiguration',
        'itemCode',
        'package1P',
        'package1T',
        'isArchived',
        'createdAt',
        'updatedAt',
        'archivedAt',
      ],
      ...items.map(
        (entry) => [
          entry.item.id,
          entry.item.name,
          entry.item.itemType.name,
          entry.item.category,
          entry.item.serialNumber ?? '',
          entry.item.codeConfiguration.name,
          entry.codeFor(ItemCodeRole.item)?.value ?? '',
          entry.codeFor(ItemCodeRole.package1P)?.value ?? '',
          entry.codeFor(ItemCodeRole.package1T)?.value ?? '',
          entry.item.isArchived,
          entry.item.createdAt.toUtc().toIso8601String(),
          entry.item.updatedAt.toUtc().toIso8601String(),
          entry.item.archivedAt?.toUtc().toIso8601String() ?? '',
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    return _writeExport('lab-inventory-${_timestamp()}.csv', csv);
  }

  Future<void> share(File file) {
    return SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Map<String, Object?> _itemToJson(InventoryEntry entry) {
    final item = entry.item;
    return {
      'id': item.id,
      'name': item.name,
      'itemType': item.itemType.name,
      'category': item.category,
      'serialNumber': item.serialNumber,
      'codeConfiguration': item.codeConfiguration.name,
      'codes': entry.codes
          .map(
            (code) => {
              'role': code.role.name,
              'type': code.codeType.name,
              'value': code.value,
              'source': code.source.name,
            },
          )
          .toList(),
      'isArchived': item.isArchived,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      'archivedAt': item.archivedAt?.toUtc().toIso8601String(),
    };
  }

  Future<File> _writeExport(String name, String contents) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'exports'));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, name));
    return file.writeAsString(contents, encoding: utf8, flush: true);
  }

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  String _timestamp() =>
      DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
}
