/// Set at build time:
///   flutter run --dart-define=API_URL=https://authentic-api.onrender.com
/// With no API_URL the app runs on the seeded in-memory world.
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL');

  static bool get isLive => apiUrl.isNotEmpty;
}
