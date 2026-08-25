import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/inventory_database.dart';

class ExportService {
  ExportService(this._database);

  final InventoryDatabase _database;

  Future<File> exportJson() async {
    final items = await _database.allItems();
    final payload = <String, Object?>{
      'schemaVersion': 1,
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
        'codeType',
        'codeValue',
        'codeSource',
        'isArchived',
        'createdAt',
        'updatedAt',
        'archivedAt',
      ],
      ...items.map(
        (item) => [
          item.id,
          item.name,
          item.itemType.name,
          item.category,
          item.serialNumber ?? '',
          item.codeType.name,
          item.codeValue,
          item.codeSource.name,
          item.isArchived,
          item.createdAt.toUtc().toIso8601String(),
          item.updatedAt.toUtc().toIso8601String(),
          item.archivedAt?.toUtc().toIso8601String() ?? '',
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    return _writeExport('lab-inventory-${_timestamp()}.csv', csv);
  }

  Future<void> share(File file) {
    return SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Map<String, Object?> _itemToJson(InventoryItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'itemType': item.itemType.name,
      'category': item.category,
      'serialNumber': item.serialNumber,
      'code': {
        'type': item.codeType.name,
        'value': item.codeValue,
        'source': item.codeSource.name,
      },
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
