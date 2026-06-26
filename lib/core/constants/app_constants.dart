// App-wide constants — API config, timeouts, free-tier limits.
//
// API keys are injected at build time via --dart-define.
// Nothing secret lives here.
abstract final class AppConstants {
  /// Groq API base URL (OpenAI-compatible).
  static const String apiBaseUrl = 'https://api.groq.com/openai/v1';

  /// HTTP timeouts.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Free-tier limits.
  static const int freeBrainstormsPerDay = 3;

  /// Whether the freemium cap is disabled for development builds.
  static const bool kDebugDisableFreemium = bool.fromEnvironment(
    'DEBUG_FREEMIUM',
    defaultValue: false,
  );

  /// Conversation limits — auto-wrap after this many exchanges.
  static const int maxExchangesBeforeWrap = 10;

  /// Groq model selection — dual-model routing.
  /// Fast/cheap model for conversation turns.
  static const String conversationModel = 'llama-3.1-8b-instant';
  /// High-quality model for final output generation.
  static const String finalOutputModel = 'llama-3.3-70b-versatile';

  /// ElevenLabs TTS config.
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsVoiceId = '21m00Tcm4TlvDq8ikWAM'; // "Rachel"
  static const String elevenLabsModelId = 'eleven_turbo_v2_5';

  /// Hive box names.
  static const String brainstormBoxName = 'brainstorms';
}
