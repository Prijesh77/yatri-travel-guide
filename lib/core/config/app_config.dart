/// Build-time configuration, passed with `--dart-define`.
///
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your-key
/// ```
///
/// Keys are never committed. An API key compiled into a mobile app can be
/// extracted, so for a public release the AI call should move behind a small
/// backend; the [AiConfig] indirection keeps that change local.
class AiConfig {
  const AiConfig({required this.apiKey, required this.model});

  /// Free key from Google AI Studio (aistudio.google.com). Empty = AI off.
  final String apiKey;

  /// Gemini model id. Flash-Lite has the most generous free quota.
  final String model;

  bool get isEnabled => apiKey.isNotEmpty;

  static const fromEnvironment = AiConfig(
    apiKey: String.fromEnvironment('GEMINI_API_KEY'),
    model: String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.1-flash-lite'),
  );
}
