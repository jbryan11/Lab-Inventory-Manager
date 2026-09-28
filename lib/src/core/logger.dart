/// Simple logging utility for the application.
/// Can be extended to use a proper logger package like 'logger' if needed.
class AppLogger {
  static const String _prefix = '[Lab Inventory]';
  static bool _debug = true;

  /// Initialize logger. Set debug=false to disable debug logs.
  static void init({bool debug = true}) {
    _debug = debug;
  }

  /// Log debug message.
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_debug) return;
    print('$_prefix [DEBUG] $message');
    if (error != null) print('  Error: $error');
    if (stackTrace != null) print('  $stackTrace');
  }

  /// Log info message.
  static void info(String message) {
    print('$_prefix [INFO] $message');
  }

  /// Log warning message.
  static void warning(String message, [Object? error]) {
    print('$_prefix [WARNING] $message');
    if (error != null) print('  Error: $error');
  }

  /// Log error message.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('$_prefix [ERROR] $message');
    if (error != null) print('  Error: $error');
    if (stackTrace != null) print('  $stackTrace');
  }
}
