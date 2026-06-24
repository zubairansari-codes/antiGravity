/// Brainstorm screen — live voice conversation with the AI agent.
///
/// Shows: voice wave animation, chat messages, and voice control bar.
/// "Wrap it up" button in the app bar triggers final output generation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/typing_indicator.dart';
import '../../../../core/widgets/animations/voice_wave.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/brainstorm_session_vm.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/voice_control_bar.dart';

class BrainstormScreen extends ConsumerStatefulWidget {
  final BrainstormCategory category;

  const BrainstormScreen({
    super.key,
    this.category = BrainstormCategory.general,
  });

  @override
  ConsumerState<BrainstormScreen> createState() =>
      _BrainstormScreenState();
}

class _BrainstormScreenState extends ConsumerState<BrainstormScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brainstormSessionVmProvider);
    final notifier = ref.read(brainstormSessionVmProvider.notifier);

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
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.category.icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(widget.category.label),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Save before leaving if there are messages.
            if (state.messages.isNotEmpty) {
              notifier.saveSession();
            }
            context.pop();
          },
        ),
        actions: [
          if (state.messages.length >= 2)
            TextButton.icon(
              onPressed: state.isProcessing
                  ? null
                  : () => notifier.generateFinalResult(),
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
        ],
      ),
      body: Column(
        children: [
          // Voice wave animation
          if (state.isListening || state.isSpeaking)
            VoiceWaveAnimation(
              isActive: state.isListening,
              isSpeaking: state.isSpeaking,
            ),

          // Chat messages
          Expanded(
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

          // Typing indicator
          if (state.isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
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
                  child: const TypingIndicator(),
                ),
              ),
            ),

          // Error banner
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: AppColors.error.withOpacity(0.1),
              child: Text(
                state.error!,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),

          // Voice control bar
          VoiceControlBar(
            isListening: state.isListening,
            onMicTap: () {
              if (state.isListening) {
                notifier.stopListening();
              } else {
                notifier.startListening();
              }
            },
            onTextSubmit: (text) => notifier.handleTextInput(text),
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
            Icon(
              Icons.record_voice_over_rounded,
              size: 48,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'What\'s on your mind?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
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
