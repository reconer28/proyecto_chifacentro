abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
