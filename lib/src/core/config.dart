abstract final class AppConfig {
  static const usarDemo = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const urlBaseApi = String.fromEnvironment('API_BASE_URL');
}
