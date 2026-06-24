/// Brainstorm session view model — manages the live voice conversation.
///
/// Tracks: messages, listening/speaking/processing states, and result.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message.dart';
import 'providers.dart';

// ── Session State ─────────────────────────────────────────────────

class BrainstormSessionState {
  final List<ChatMessage> messages;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final BrainstormResult? result;
  final String? error;
  final String sessionId;
  final BrainstormCategory category;

  const BrainstormSessionState({
    this.messages = const [],
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.result,
    this.error,
    this.sessionId = '',
    this.category = BrainstormCategory.general,
  });

  BrainstormSessionState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    BrainstormResult? result,
    String? error,
    String? sessionId,
    BrainstormCategory? category,
  }) {
    return BrainstormSessionState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────

final brainstormSessionVmProvider = StateNotifierProvider.autoDispose<
    BrainstormSessionVm, BrainstormSessionState>(
  (ref) => BrainstormSessionVm(ref),
);

class BrainstormSessionVm extends StateNotifier<BrainstormSessionState> {
  final Ref _ref;
  bool _speechInitialized = false;

  /// Keeps track of whether we're in continuous back-and-forth mode.
  bool _continuousMode = false;

  /// Prevents double-firing if both silence timeout and status event trigger.
  bool _isProcessing = false;

  BrainstormSessionVm(this._ref) : super(const BrainstormSessionState());

  /// Initialize speech service (requests mic permission on first call).
  Future<bool> _ensureSpeechInit() async {
    if (_speechInitialized) return true;
    try {
      final speechService = _ref.read(speechServiceProvider);
      final ok = await speechService.initialize();
      _speechInitialized = ok;
      if (!ok) {
        state = state.copyWith(
          error: 'Microphone permission denied. Use the keyboard instead.',
        );
      }
      return ok;
    } catch (e) {
      state = state.copyWith(
        error: 'Could not access microphone: $e',
      );
      return false;
    }
  }

  /// Start voice listening (enters continuous conversation mode).
  Future<void> startListening() async {
    // Initialize speech service (requests mic permission).
    final ready = await _ensureSpeechInit();
    if (!ready) return;

    _continuousMode = true;
    await _startListeningInternal();
  }

  /// Load an existing session from local storage.
  Future<void> loadSession(String sessionId) async {
    final repo = _ref.read(brainstormRepositoryProvider);
    final historyOrFailure = await repo.getBrainstormHistory();

    historyOrFailure.fold(
      (f) => state = state.copyWith(error: f.message),
      (sessions) {
        final session = sessions.firstWhere(
          (s) => s.id == sessionId,
          orElse: () => Brainstorm(
            id: sessionId,
            title: 'Unknown',
            messages: [],
            createdAt: DateTime.now(),
          ),
        );

        state = state.copyWith(
          sessionId: session.id,
          messages: session.messages,
          result: session.result,
          category: session.category,
        );
      },
    );
  }

  /// Start a new session.
  Future<void> startNewSession(BrainstormCategory category) async {
    final repo = _ref.read(brainstormRepositoryProvider);
    final result = await repo.createSession(category: category);

    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (brainstorm) {
        state = state.copyWith(
          sessionId: brainstorm.id,
          category: brainstorm.category,
        );
        _startListeningInternal();
      },
    );
  }

  /// Stop voice listening (exits continuous conversation mode).
  Future<void> stopListening() async {
    _continuousMode = false;
    state = state.copyWith(isListening: false);
    final speechService = _ref.read(speechServiceProvider);
    await speechService.stopListening();
    await speechService.stopSpeaking();
  }

  /// Internal: start a single listening session.
  Future<void> _startListeningInternal() async {
    if (!_continuousMode) return;
    if (state.isListening) return; // Already listening, skip.

    // Small delay to let web SpeechRecognition engine clean up.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_continuousMode) return; // Check again after delay.

    final speechService = _ref.read(speechServiceProvider);
    // Ensure any previous session is stopped.
    await speechService.stopListening();

    state = state.copyWith(isListening: true, error: null);
    debugPrint('[AG] startListening: began (continuous=$_continuousMode)');

    try {
      await speechService.startListening(
        onResult: (text) {
          debugPrint('[AG] STT result: "$text"');
          _handleUserInput(text);
        },
        onError: (error) {
          debugPrint('[AG] STT error: $error');
          state = state.copyWith(
            isListening: false,
            error: error,
          );
          // Auto-retry listening after error in continuous mode.
          if (_continuousMode) {
            Future.delayed(const Duration(seconds: 1), _startListeningInternal);
          }
        },
      );
    } catch (e) {
      debugPrint('[AG] STT exception: $e');
      state = state.copyWith(
        isListening: false,
        error: 'Could not start voice recognition: $e',
      );
    }
  }

  /// Handle text input (from voice or keyboard).
  Future<void> handleTextInput(String text) async {
    await _handleUserInput(text);
  }

  /// Minimum word count to consider input as real speech (not noise).
  static const int _minWordCount = 2;
  static const int _minCharCount = 5;

  /// Process user input: add to messages, send to AI, play response, auto-listen.
  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) {
      debugPrint('[AG] _handleUserInput: empty text, ignoring');
      return;
    }

    // Guard: reject if already processing (prevents double-fire).
    if (state.isProcessing) {
      debugPrint('[AG] _handleUserInput: already processing, ignoring duplicate');
      return;
    }

    // Noise filter: reject very short inputs (random syllables, coughs, etc.)
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length < _minWordCount || text.trim().length < _minCharCount) {
      debugPrint('[AG] _handleUserInput: noise rejected (${words.length} words, ${text.trim().length} chars): "$text"');
      // Reset listening state since the STT stopped to fire this result.
      state = state.copyWith(isListening: false);
      // Auto-restart listening if in continuous mode.
      if (_continuousMode) {
        await _startListeningInternal();
      }
      return;
    }

    debugPrint('[AG] _handleUserInput: "$text"');

    // Add user message.
    final userMessage = ChatMessage.user(text);
    final updatedMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: updatedMessages,
      isListening: false,
      isProcessing: true,
      error: null,
    );

    // Check if user wants to wrap up.
    final wantsWrapUp = _isWrapUpRequest(text);

    // Send to AI.
    debugPrint('[AG] Sending to Groq API (wrapUp=$wantsWrapUp)...');
    final useCase = _ref.read(sendMessageUseCaseProvider);
    final result = await useCase(SendMessageParams(
      messages: updatedMessages,
      requestFinalOutput: wantsWrapUp,
      category: state.category,
    ));

    result.fold(
      (failure) {
        debugPrint('[AG] API FAILURE: ${failure.message}');
        state = state.copyWith(
          isProcessing: false,
          error: failure.message,
        );
        // Auto-resume listening even on API error.
        if (_continuousMode) {
          Future.delayed(const Duration(seconds: 1), _startListeningInternal);
        }
      },
      (aiResponse) async {
        debugPrint('[AG] API SUCCESS: "${aiResponse.text.substring(0, aiResponse.text.length.clamp(0, 80))}..."');

        // Add AI message.
        final aiMessage = ChatMessage.assistant(aiResponse.text);
        final allMessages = [...updatedMessages, aiMessage];

        state = state.copyWith(
          messages: allMessages,
          isProcessing: false,
          isSpeaking: true,
        );

        // Speak the response via ElevenLabs.
        try {
          final speechService = _ref.read(speechServiceProvider);
          await speechService.speak(aiResponse.text);
        } catch (e) {
          debugPrint('[AG] TTS error: $e');
        }

        state = state.copyWith(isSpeaking: false);

        // If final result, set it and stop continuous mode.
        if (aiResponse.isFinal && aiResponse.structuredResult != null) {
          _continuousMode = false;
          state = state.copyWith(result: aiResponse.structuredResult);
        } else {
          // Auto-restart listening for seamless conversation.
          if (_continuousMode) {
            debugPrint('[AG] Auto-restarting listener...');
            await _startListeningInternal();
          }
        }
      },
    );
  }

  /// Explicitly generate the final result.
  Future<void> generateFinalResult() async {
    if (state.messages.isEmpty) return;

    state = state.copyWith(isProcessing: true, error: null);

    final useCase = _ref.read(sendMessageUseCaseProvider);
    final result = await useCase(SendMessageParams(
      messages: state.messages,
      requestFinalOutput: true,
      category: state.category,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          isProcessing: false,
          error: failure.message,
        );
      },
      (aiResponse) {
        final aiMessage = ChatMessage.assistant(aiResponse.text);
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isProcessing: false,
          result: aiResponse.structuredResult,
        );
      },
    );
  }

  /// Save the current session to local storage.
  Future<void> saveSession() async {
    final repo = _ref.read(brainstormRepositoryProvider);

    // Derive title from first user message.
    final firstUserMsg = state.messages
        .where((m) => m.role == MessageRole.user)
        .firstOrNull;
    final title = firstUserMsg != null
        ? (firstUserMsg.content.length > 50
            ? '${firstUserMsg.content.substring(0, 50)}…'
            : firstUserMsg.content)
        : 'Untitled Brainstorm';

    final brainstorm = Brainstorm(
      id: state.sessionId,
      title: title,
      messages: state.messages,
      result: state.result,
      createdAt: DateTime.now(),
    );

    await repo.saveBrainstorm(brainstorm);
  }

  /// Check if the user's input is a "wrap it up" request.
  bool _isWrapUpRequest(String text) {
    final lower = text.toLowerCase().trim();
    const triggers = [
      'wrap it up',
      'wrap up',
      'give me my plan',
      "i'm done",
      'im done',
      'finish',
      'finalize',
      'that\'s it',
      'thats it',
      'let\'s go',
      'generate',
      'done',
    ];
    return triggers.any((t) => lower.contains(t));
  }
}
