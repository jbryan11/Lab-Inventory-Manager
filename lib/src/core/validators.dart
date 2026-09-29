import '../core/exceptions.dart';

/// Validates inventory data before storage.
class InventoryValidator {
  // Validation constraints
  static const int minNameLength = 1;
  static const int maxNameLength = 200;
  static const int minCategoryLength = 1;
  static const int maxCategoryLength = 100;
  static const int minCodeLength = 1;
  static const int maxCodeLength = 500;

  /// Validates item name.
  ///
  /// Throws [ValidationException] if validation fails.
  static void validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Item name cannot be empty');
    }
    if (trimmed.length < minNameLength) {
      throw ValidationException(
        'Item name must be at least $minNameLength character',
      );
    }
    if (trimmed.length > maxNameLength) {
      throw ValidationException(
        'Item name must not exceed $maxNameLength characters '
        '(current: ${trimmed.length})',
      );
    }
  }

  /// Validates item category.
  ///
  /// Throws [ValidationException] if validation fails.
  static void validateCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Category cannot be empty');
    }
    if (trimmed.length < minCategoryLength) {
      throw ValidationException(
        'Category must be at least $minCategoryLength character',
      );
    }
    if (trimmed.length > maxCategoryLength) {
      throw ValidationException(
        'Category must not exceed $maxCategoryLength characters '
        '(current: ${trimmed.length})',
      );
    }
  }

  /// Validates serial number (optional field).
  ///
  /// Throws [ValidationException] if validation fails.
  static void validateSerialNumber(String? serialNumber) {
    if (serialNumber != null && serialNumber.trim().isEmpty) {
      throw ValidationException(
        'Serial number cannot be an empty string. Use null instead.',
      );
    }
  }

  /// Validates barcode/code value.
  ///
  /// Throws [ValidationException] if validation fails.
  static void validateCodeValue(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Code value cannot be empty');
    }
    if (trimmed.length < minCodeLength) {
      throw ValidationException(
        'Code must be at least $minCodeLength character',
      );
    }
    if (trimmed.length > maxCodeLength) {
      throw ValidationException(
        'Code must not exceed $maxCodeLength characters (current: ${trimmed.length})',
      );
    }
  }

  /// Batch validation for a complete item.
  ///
  /// Throws [ValidationException] if any field fails validation.
  static void validateItem({
    required String name,
    required String category,
    String? serialNumber,
    required List<String> codesToValidate,
  }) {
    validateName(name);
    validateCategory(category);
    validateSerialNumber(serialNumber);

    if (codesToValidate.isEmpty) {
      throw ValidationException('At least one code must be provided');
    }

    for (final code in codesToValidate) {
      validateCodeValue(code);
    }
  }
}
