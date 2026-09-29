import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory_manager/src/core/exceptions.dart';
import 'package:lab_inventory_manager/src/core/validators.dart';

void main() {
  group('InventoryValidator', () {
    group('validateName', () {
      test('accepts minimum and maximum lengths', () {
        expect(() => InventoryValidator.validateName('A'), returnsNormally);
        expect(
          () => InventoryValidator.validateName(_text(200)),
          returnsNormally,
        );
      });

      test('rejects empty and whitespace-only names', () {
        for (final value in ['', '   ']) {
          expect(
            () => InventoryValidator.validateName(value),
            throwsA(isA<ValidationException>()),
          );
        }
      });

      test('rejects names over 200 characters', () {
        expect(
          () => InventoryValidator.validateName(_text(201)),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              contains('200'),
            ),
          ),
        );
      });
    });

    group('validateCategory', () {
      test('accepts minimum and maximum lengths', () {
        expect(() => InventoryValidator.validateCategory('A'), returnsNormally);
        expect(
          () => InventoryValidator.validateCategory(_text(100)),
          returnsNormally,
        );
      });

      test('rejects empty and whitespace-only categories', () {
        for (final value in ['', '   ']) {
          expect(
            () => InventoryValidator.validateCategory(value),
            throwsA(isA<ValidationException>()),
          );
        }
      });

      test('rejects categories over 100 characters', () {
        expect(
          () => InventoryValidator.validateCategory(_text(101)),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateCodeValue', () {
      test('accepts trimmed values at the maximum length', () {
        expect(
          () => InventoryValidator.validateCodeValue('  ${_text(500)}  '),
          returnsNormally,
        );
      });

      test('rejects empty and whitespace-only codes', () {
        for (final value in ['', '   ']) {
          expect(
            () => InventoryValidator.validateCodeValue(value),
            throwsA(isA<ValidationException>()),
          );
        }
      });

      test('rejects codes over 500 characters', () {
        expect(
          () => InventoryValidator.validateCodeValue(_text(501)),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateSerialNumber', () {
      test('accepts null and non-empty values', () {
        expect(
          () => InventoryValidator.validateSerialNumber(null),
          returnsNormally,
        );
        expect(
          () => InventoryValidator.validateSerialNumber('SN-100'),
          returnsNormally,
        );
      });

      test('rejects empty and whitespace-only values', () {
        for (final value in ['', '   ']) {
          expect(
            () => InventoryValidator.validateSerialNumber(value),
            throwsA(isA<ValidationException>()),
          );
        }
      });
    });

    group('validateItem', () {
      test('accepts a complete valid item', () {
        expect(
          () => InventoryValidator.validateItem(
            name: 'Bench meter',
            category: 'Test equipment',
            serialNumber: 'SN-100',
            codesToValidate: ['ITEM-100'],
          ),
          returnsNormally,
        );
      });

      test('requires at least one code', () {
        expect(
          () => InventoryValidator.validateItem(
            name: 'Bench meter',
            category: 'Test equipment',
            codesToValidate: const [],
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              contains('At least one code'),
            ),
          ),
        );
      });
    });
  });
}

String _text(int length) => List.filled(length, 'a').join();
