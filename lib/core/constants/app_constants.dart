/// App-wide constants — API config, timeouts, free-tier limits.
///
/// API keys are loaded from `.env` at runtime via flutter_dotenv.
/// Nothing secret lives here.
library;

abstract final class AppConstants {
  /// Groq API base URL (OpenAI-compatible).
  static const String apiBaseUrl = 'https://api.groq.com/openai/v1';

  /// HTTP timeouts.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Free-tier limits.
  static const int freeBrainstormsPerDay = 3;

  /// Conversation limits — auto-wrap after this many exchanges.
  static const int maxExchangesBeforeWrap = 10;

  /// Groq model selection — Llama 3.3 70B for quality, 8B for speed.
  static const String conversationModel = 'llama-3.3-70b-versatile';
  static const String finalOutputModel = 'llama-3.3-70b-versatile';

  /// ElevenLabs TTS config.
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsVoiceId = 'TxGEqnHWrfWFTfGW9XjX'; // "Josh"
  static const String elevenLabsModelId = 'eleven_turbo_v2_5';

  /// Hive box names.
  static const String brainstormBoxName = 'brainstorms';
}
