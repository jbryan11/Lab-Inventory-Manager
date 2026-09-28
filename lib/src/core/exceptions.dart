/// Application-wide exception hierarchy for consistent error handling.
abstract class AppException implements Exception {
  AppException(this.message, {this.originalError, this.stackTrace});

  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Database-related exceptions.
class DatabaseException extends AppException {
  DatabaseException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Input validation exceptions.
class ValidationException extends AppException {
  ValidationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Barcode/code parsing exceptions.
class CodeParsingException extends AppException {
  CodeParsingException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// File I/O exceptions (export/import).
class FileException extends AppException {
  FileException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Migration-related exceptions.
class MigrationException extends AppException {
  MigrationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}
