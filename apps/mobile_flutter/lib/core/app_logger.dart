import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Small, dependency-free event logger for local/preview diagnostics.
///
/// Release builds intentionally do not emit console events. A crash-reporting
/// provider can be attached here later without exposing credentials or tokens.
class AppLogger {
  const AppLogger._();

  static void event(
    String name, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (kReleaseMode) return;
    final safeFields = <String, Object?>{};
    for (final entry in fields.entries) {
      final key = entry.key.toLowerCase();
      safeFields[entry.key] = _sensitiveKeys.any(key.contains)
          ? '[REDACTED]'
          : entry.value;
    }
    debugPrint(
      jsonEncode(<String, Object?>{
        'event': name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'fields': safeFields,
      }),
    );
  }

  static const _sensitiveKeys = <String>[
    'authorization',
    'token',
    'secret',
    'password',
    'api_key',
    'apikey',
  ];
}
