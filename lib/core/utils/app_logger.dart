import 'package:flutter/foundation.dart';

/// Simple logger utility for the app.
/// In production, debug logs are disabled.
/// Only error logs are shown in release mode.
class AppLogger {
  static const String _tag = 'KuponBBM';

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] $message');
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ℹ️ $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ⚠️ $message');
    }
  }

  /// Log error messages (always shown)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[${tag ?? _tag}] ❌ $message');
    if (error != null) {
      debugPrint('[${tag ?? _tag}] Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('[${tag ?? _tag}] StackTrace: $stackTrace');
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ✅ $message');
    }
  }
}
