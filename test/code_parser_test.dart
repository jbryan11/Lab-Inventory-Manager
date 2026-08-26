import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/domain/inventory_enums.dart';
import 'package:lab_inventory_manager/src/features/scanner/code_parser.dart';

void main() {
  test('classifies and strips package code prefixes', () {
    final oneP = parseScannedCode(' (1P) PART-123 ');
    final oneT = parseScannedCode('1t: TRACE-456');

    expect(oneP?.role, ItemCodeRole.package1P);
    expect(oneP?.value, 'PART-123');
    expect(oneT?.role, ItemCodeRole.package1T);
    expect(oneT?.value, 'TRACE-456');
  });

  test('preserves an unclassified item code', () {
    final parsed = parseScannedCode('  ITEM-789  ');

    expect(parsed?.role, isNull);
    expect(parsed?.value, 'ITEM-789');
  });

  test('rejects empty values and classifiers without payloads', () {
    expect(parseScannedCode(''), isNull);
    expect(parseScannedCode('(1P)'), isNull);
    expect(parseScannedCode('1T:  '), isNull);
  });
}
