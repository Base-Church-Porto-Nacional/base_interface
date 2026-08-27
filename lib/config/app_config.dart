class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );
}
