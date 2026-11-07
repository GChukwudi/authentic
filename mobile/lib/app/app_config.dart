/// Set at build time:
///   flutter run --dart-define=API_URL=https://authentic-api.onrender.com
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL');

  static bool get isConfigured => apiUrl.isNotEmpty;
}
