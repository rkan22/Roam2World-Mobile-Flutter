class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://roam2world-panels-backend.onrender.com',
  );

  static const String appName = 'Roam2World B2B';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static bool isSafeReleaseApiUrl([String value = apiBaseUrl]) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;

    final host = uri.host.toLowerCase();
    return host != 'localhost' &&
        host != '127.0.0.1' &&
        host != '10.0.2.2' &&
        !host.endsWith('.local');
  }

  static void validateReleaseConfiguration() {
    if (!isSafeReleaseApiUrl()) {
      throw StateError(
        'Release builds require a public HTTPS API_BASE_URL. '
        'Current value: $apiBaseUrl',
      );
    }
  }
}
