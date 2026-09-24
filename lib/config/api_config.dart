class ApiConfig {
  static const String configuredUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mindease-backend-production-3a83.up.railway.app',
  );
  static String normalize(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery ||
        uri.hasFragment || (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError('API_BASE_URL debe ser el origen HTTP(S), sin /api ni credenciales.');
    }
    return uri.origin;
  }
  static final String baseUrl = normalize(configuredUrl);
}
