class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const devUserId = String.fromEnvironment(
    'DEV_USER_ID',
    defaultValue: '00000000-0000-4000-8000-000000000099',
  );
  static const flavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: String.fromEnvironment(
      'FLUTTER_APP_FLAVOR',
      defaultValue: 'dev',
    ),
  );
  static const devAuthEnabled = bool.fromEnvironment(
    'DEV_AUTH_ENABLED',
    defaultValue: true,
  );

  static bool get useDevAuth => devAuthEnabled && flavor != 'production';

  static bool isProductionSafeApiBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
    return !localHosts.contains(uri.host.toLowerCase());
  }

  static void validateForProduction() {
    if (flavor == 'production' && !isProductionSafeApiBaseUrl(apiBaseUrl)) {
      throw StateError(
        'Production requires an explicit HTTPS API_BASE_URL on a non-local host.',
      );
    }
  }
}
