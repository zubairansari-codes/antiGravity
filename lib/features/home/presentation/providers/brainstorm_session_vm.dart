/// Brainstorm session view model — manages the live voice conversation.
///
/// Tracks: messages, listening/speaking/processing states, result, and live transcript.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message.dart';
import 'providers.dart';
import 'settings_providers.dart';

// ── Session State ─────────────────────────────────────────────────

class BrainstormSessionState {

  const BrainstormSessionState({
    this.messages = const [],
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.result,
    this.error,
    this.sessionId = '',
    this.category = BrainstormCategory.general,
    this.liveTranscript,
    this.showPaywall = false,
  });
  final List<ChatMessage> messages;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final BrainstormResult? result;
  final String? error;
  final String sessionId;
  final BrainstormCategory category;
  final String? liveTranscript;
  final bool showPaywall;

  BrainstormSessionState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    BrainstormResult? result,
    String? error,
    String? sessionId,
    BrainstormCategory? category,
    String? liveTranscript,
    bool? showPaywall,
  }) {
    return BrainstormSessionState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      error: error ?? this.error,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      showPaywall: showPaywall ?? this.showPaywall,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────

final brainstormSessionVmProvider =
    AutoDisposeNotifierProvider<BrainstormSessionVm, BrainstormSessionState>(
  BrainstormSessionVm.new,
);

class BrainstormSessionVm extends AutoDisposeNotifier<BrainstormSessionState> {
  bool _speechInitialized = false;

  /// Keeps track of whether we're in continuous back-and-forth mode.
  bool _continuousMode = false;

  /// Timer for auto-retrying listening after error.
  Timer? _restartTimer;

  /// Timer for clearing live transcript after final result.
  Timer? _transcriptClearTimer;

  @override
  BrainstormSessionState build() {
    // Register cleanup callbacks for Riverpod 2.x disposal.
    ref.onDispose(dispose);
    return const BrainstormSessionState();
  }

  /// Dispose resources — stops speech service and cancels any pending timers.
  void dispose() {
    debugPrint('[AG] BrainstormSessionVm.dispose() called');
    _continuousMode = false;
    _restartTimer?.cancel();
    _transcriptClearTimer?.cancel();

    try {
      final speechService = ref.read(speechServiceProvider);
      speechService.stopListening();
      speechService.stopSpeaking();
    } catch (e) {
      debugPrint('[AG] dispose error: $e');
    }
  }

  /// Initialize speech service (requests mic permission on first call).
  Future<bool> _ensureSpeechInit() async {
    if (_speechInitialized) return true;
    try {
      final speechService = ref.read(speechServiceProvider);
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
    final repo = ref.read(brainstormRepositoryProvider);
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
    // Freemium check: enforce daily limit.
    final tracker = ref.read(dailyUsageTrackerProvider);
    final dailyCount = await tracker.getDailyCount();
    if (dailyCount >= AppConstants.freeBrainstormsPerDay) {
      state = state.copyWith(showPaywall: true);
      return;
    }

    // Increment usage count.
    await tracker.increment();
    // Invalidate daily count provider so UI refreshes.
    ref.invalidate(dailyCountProvider);

    final repo = ref.read(brainstormRepositoryProvider);
    final result = await repo.createSession(category: category);

    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (brainstorm) {
        state = state.copyWith(
          sessionId: brainstorm.id,
          category: brainstorm.category,
        );
        // Initialize speech and start the continuous listening loop.
        startListening();
      },
    );
  }

  /// Dismiss the paywall modal.
  void dismissPaywall() {
    state = state.copyWith(showPaywall: false);
  }

  /// Stop voice listening (exits continuous conversation mode).
  Future<void> stopListening() async {
    _continuousMode = false;
    state = state.copyWith(isListening: false, liveTranscript: null);
    final speechService = ref.read(speechServiceProvider);
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

    final speechService = ref.read(speechServiceProvider);
    // Ensure any previous session is stopped.
    await speechService.stopListening();

    state = state.copyWith(isListening: true, error: null, liveTranscript: null);
    debugPrint('[AG] startListening: began (continuous=$_continuousMode)');

    try {
      await speechService.startListening(
        onResult: (text) {
          debugPrint('[AG] STT result: "$text"');
          state = state.copyWith(liveTranscript: null);
          _handleUserInput(text);
        },
        onError: (error) {
          debugPrint('[AG] STT error: $error');
          state = state.copyWith(
            isListening: false,
            liveTranscript: null,
            error: error,
          );
          // Auto-retry listening after error in continuous mode.
          if (_continuousMode) {
            _restartTimer?.cancel();
            _restartTimer = Timer(const Duration(seconds: 1), () {
              if (_continuousMode) _startListeningInternal();
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[AG] STT exception: $e');
      state = state.copyWith(
        isListening: false,
        liveTranscript: null,
        error: 'Could not start voice recognition: $e',
      );
    }
  }

  /// Handle text input (from voice or keyboard).
  Future<void> handleTextInput(String text) async {
    await _handleUserInput(text);
  }

  /// Update live transcript from partial STT results.
  void updateLiveTranscript(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(liveTranscript: text);
  }

  /// Interrupt AI speaking and immediately start listening (barge-in).
  Future<void> interruptAndListen() async {
    debugPrint('[AG] Barge-in: interrupting AI and restarting listening');
    final speechService = ref.read(speechServiceProvider);
    await speechService.stopSpeaking();
    state = state.copyWith(isSpeaking: false);
    HapticFeedback.mediumImpact();
    await startListening();
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
      state = state.copyWith(isListening: false, liveTranscript: null);
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

    // Check if conversation limit reached.
    if (updatedMessages.length >= AppConstants.maxExchangesBeforeWrap * 2) {
      debugPrint('[AG] Max exchanges reached (${updatedMessages.length} messages). Auto-wrapping up.');
      final limitMessage = ChatMessage.assistant(
        "You've reached the conversation limit. Let me wrap up your brainstorm.",
      );
      state = state.copyWith(
        messages: [...updatedMessages, limitMessage],
        isListening: false,
        isProcessing: true,
        liveTranscript: null,
        error: null,
      );
      HapticFeedback.heavyImpact();
      await generateFinalResult();
      return;
    }

    state = state.copyWith(
      messages: updatedMessages,
      isListening: false,
      isProcessing: true,
      liveTranscript: null,
      error: null,
    );

    // Check if user wants to wrap up.
    final wantsWrapUp = _isWrapUpRequest(text);

    // Send to AI.
    debugPrint('[AG] Sending to Groq API (wrapUp=$wantsWrapUp)...');
    final useCase = ref.read(sendMessageUseCaseProvider);
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
        HapticFeedback.heavyImpact();
        // Auto-resume listening even on API error.
        if (_continuousMode) {
          _restartTimer?.cancel();
          _restartTimer = Timer(const Duration(seconds: 1), () {
            if (_continuousMode) _startListeningInternal();
          });
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

        HapticFeedback.mediumImpact();

        // Speak the response via ElevenLabs.
        try {
          final speechService = ref.read(speechServiceProvider);
          await speechService.speak(aiResponse.text);
        } catch (e) {
          debugPrint('[AG] TTS error: $e');
        }

        state = state.copyWith(isSpeaking: false);

        // If final result, set it and stop continuous mode.
        if (aiResponse.isFinal && aiResponse.structuredResult != null) {
          _continuousMode = false;
          state = state.copyWith(result: aiResponse.structuredResult);
          HapticFeedback.vibrate();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.vibrate();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.vibrate();
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

    final useCase = ref.read(sendMessageUseCaseProvider);
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
        HapticFeedback.heavyImpact();
      },
      (aiResponse) {
        final aiMessage = ChatMessage.assistant(aiResponse.text);
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isProcessing: false,
          result: aiResponse.structuredResult,
        );
        HapticFeedback.vibrate();
        Future.delayed(const Duration(milliseconds: 100), HapticFeedback.vibrate);
        Future.delayed(const Duration(milliseconds: 200), HapticFeedback.vibrate);
      },
    );
  }

  /// Save the current session to local storage.
  Future<void> saveSession() async {
    final repo = ref.read(brainstormRepositoryProvider);

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
