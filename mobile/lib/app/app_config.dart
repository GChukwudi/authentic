abstract final class AppConfig {
  /// The deployed backend. Override for a local one with
  ///   flutter run --dart-define=API_URL=http://localhost:8787
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://authentic-9fw1.onrender.com',
  );
}
