/// Brainstorm screen — live voice conversation with the AI agent.
///
/// Shows: voice wave animation, chat messages, live transcript, voice control bar,
/// barge-in support, accessibility labels, and paywall modal.
library;


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/typing_indicator.dart';
import '../../../../core/widgets/animations/voice_wave.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/brainstorm_session_vm.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/voice_control_bar.dart';

class BrainstormScreen extends ConsumerStatefulWidget {

  const BrainstormScreen({
    super.key,
    this.category = BrainstormCategory.general,
  });
  final BrainstormCategory category;

  @override
  ConsumerState<BrainstormScreen> createState() => _BrainstormScreenState();
}

class _BrainstormScreenState extends ConsumerState<BrainstormScreen> {
  final _scrollController = ScrollController();
  Timer? _liveTranscriptTimer;

  @override
  void dispose() {
    _scrollController.dispose();
    _liveTranscriptTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Start session with chosen category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brainstormSessionVmProvider.notifier).startNewSession(widget.category);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Poll the speech-to-text singleton for partial results.
  void _startLiveTranscriptPolling() {
    _liveTranscriptTimer?.cancel();
    _liveTranscriptTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        final notifier = ref.read(brainstormSessionVmProvider.notifier);
        final words = stt.SpeechToText().lastRecognizedWords;
        if (words.isNotEmpty) {
          notifier.updateLiveTranscript(words);
        }
      },
    );
  }

  void _stopLiveTranscriptPolling() {
    _liveTranscriptTimer?.cancel();
    _liveTranscriptTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brainstormSessionVmProvider);
    final notifier = ref.read(brainstormSessionVmProvider.notifier);

    // Start/stop live transcript polling based on listening state.
    if (state.isListening) {
      _startLiveTranscriptPolling();
    } else {
      _stopLiveTranscriptPolling();
    }

    // Listen for result → navigate to result screen.
    ref.listen(brainstormSessionVmProvider, (prev, next) {
      if (next.result != null && prev?.result == null) {
        // Save session before navigating.
        notifier.saveSession();
        context.push('/result', extra: next.result);
      }

      // Auto-scroll on new messages.
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }

      // Show paywall if triggered.
      if (next.showPaywall && !(prev?.showPaywall ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showPaywallModal(context);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Brainstorming with ${widget.category.label}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.category.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(widget.category.label),
            ],
          ),
        ),
        leading: Semantics(
          label: 'Back to home',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              // Save before leaving if there are messages.
              if (state.messages.isNotEmpty) {
                notifier.saveSession();
              }
              context.pop();
            },
          ),
        ),
        actions: [
          if (state.messages.length >= 2)
            Semantics(
              label: 'Wrap up and generate final plan',
              button: true,
              child: TextButton.icon(
                onPressed: state.isProcessing
                    ? null
                    : () {
                        HapticFeedback.heavyImpact();
                        notifier.generateFinalResult();
                      },
                icon: Icon(Icons.auto_awesome,
                    size: 18,
                    color: state.isProcessing ? null : AppColors.accent),
                label: Text(
                  'WRAP UP',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: state.isProcessing ? null : AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Voice wave animation
          if (state.isListening || state.isSpeaking)
            ExcludeSemantics(
              child: VoiceWaveAnimation(
                isActive: state.isListening,
                isSpeaking: state.isSpeaking,
              ),
            ),

          // Barge-in indicator
          if (state.isSpeaking)
            Semantics(
              label: 'AI is speaking. Tap the chat area to interrupt.',
              child: GestureDetector(
                onTap: () => notifier.interruptAndListen(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: AppColors.accent.withOpacity(0.1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: AppColors.accent),
                      SizedBox(width: 6),
                      Text(
                        'Tap to interrupt',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chat messages + barge-in handler
          Expanded(
            child: GestureDetector(
              onTap: state.isSpeaking
                  ? () => notifier.interruptAndListen()
                  : null,
              behavior: HitTestBehavior.translucent,
              child: state.messages.isEmpty
                  ? _WelcomePrompt()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return ChatBubble(
                          message: msg,
                          isUser: msg.role == MessageRole.user,
                        );
                      },
                    ),
            ),
          ),

          // Live transcript preview
          if (state.liveTranscript != null && state.isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Semantics(
                label: 'Live transcript: ${state.liveTranscript}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    state.liveTranscript!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),

          // Typing indicator
          if (state.isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Semantics(
                label: 'AI is thinking',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const ExcludeSemantics(
                      child: TypingIndicator(),
                    ),
                  ),
                ),
              ),
            ),

          // Error banner with LiveRegion
          if (state.error != null)
            Semantics(
              liveRegion: true,
              label: 'Error: ${state.error}',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppColors.error.withOpacity(0.1),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          // Voice control bar
          VoiceControlBar(
            isListening: state.isListening,
            onMicTap: () {
              if (state.isListening) {
                HapticFeedback.lightImpact();
                notifier.stopListening();
              } else {
                HapticFeedback.lightImpact();
                notifier.startListening();
              }
            },
            onTextSubmit: (text) => notifier.handleTextInput(text),
          ),
        ],
      ),
    );
  }

  void _showPaywallModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _PaywallSheet(),
    );
  }
}

class _PaywallSheet extends ConsumerWidget {
  const _PaywallSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You've used your 3 free brainstorms today!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upgrade to AntiGravity Pro for unlimited brainstorming.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Feature checklist
          const _FeatureCheck(icon: Icons.all_inclusive, text: 'Unlimited sessions'),
          const _FeatureCheck(icon: Icons.record_voice_over, text: 'Premium voices'),
          const _FeatureCheck(icon: Icons.dark_mode, text: 'Dark mode'),
          const _FeatureCheck(icon: Icons.share, text: 'Export to PDF & Markdown'),
          const _FeatureCheck(icon: Icons.support_agent, text: 'Priority support'),

          const SizedBox(height: 24),

          // Primary CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start 7-Day Free Trial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                ref.read(brainstormSessionVmProvider.notifier).dismissPaywall();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Maybe Later'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCheck extends StatelessWidget {

  const _FeatureCheck({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _WelcomePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.record_voice_over_rounded,
                size: 48,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What\'s on your mind?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the mic and tell me your idea.\nI\'ll challenge it, sharpen it, and\ngive you a plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
