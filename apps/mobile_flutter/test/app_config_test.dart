import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/config/app_config.dart';

void main() {
  test('accepts HTTPS non-local production API URLs', () {
    expect(
      AppConfig.isProductionSafeApiBaseUrl('https://api.example.com'),
      isTrue,
    );
  });

  test('rejects insecure and local production API URLs', () {
    expect(
      AppConfig.isProductionSafeApiBaseUrl('http://api.example.com'),
      isFalse,
    );
    expect(
      AppConfig.isProductionSafeApiBaseUrl('https://127.0.0.1:8000'),
      isFalse,
    );
  });
}
