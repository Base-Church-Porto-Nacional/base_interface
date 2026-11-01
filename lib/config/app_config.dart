class AppConfig {
  static const _release = bool.fromEnvironment('dart.vm.product');

  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const apiUrlDefinida = bool.hasEnvironment('API_URL');

  static String? get erroDeConfiguracao {
    if (_release && !apiUrlDefinida) {
      return 'Build de produção sem API_URL. Gere novamente com '
          '--dart-define=API_URL=https://<servidor>/api';
    }
    return null;
  }
}
