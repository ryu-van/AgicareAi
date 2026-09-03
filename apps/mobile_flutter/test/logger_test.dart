import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/core/app_logger.dart';

void main() {
  test('redacts sensitive structured logging fields', () {
    String? output;
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => output = message;
    try {
      AppLogger.event(
        'api.request',
        fields: {'authorization': 'Bearer dev:secret-user', 'path': '/health'},
      );
    } finally {
      debugPrint = previousDebugPrint;
    }

    expect(output, contains('[REDACTED]'));
    expect(output, isNot(contains('secret-user')));
    expect(output, contains('/health'));
  });
}
