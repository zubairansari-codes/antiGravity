/// Voice control bar — bottom bar with mic button and text input fallback.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class VoiceControlBar extends StatefulWidget {
  final bool isListening;
  final VoidCallback onMicTap;
  final ValueChanged<String>? onTextSubmit;

  const VoiceControlBar({
    super.key,
    required this.isListening,
    required this.onMicTap,
    this.onTextSubmit,
  });

  @override
  State<VoiceControlBar> createState() => _VoiceControlBarState();
}

class _VoiceControlBarState extends State<VoiceControlBar> {
  final _textController = TextEditingController();
  bool _showTextField = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _showTextField ? _buildTextInput() : _buildVoiceControl(),
      ),
    );
  }

  Widget _buildVoiceControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Keyboard toggle
        IconButton(
          onPressed: () => setState(() => _showTextField = true),
          icon: const Icon(Icons.keyboard_outlined),
          color: AppColors.onSurfaceVariant,
          tooltip: 'Type instead',
        ),

        const SizedBox(width: 16),

        // Mic button — hero element
        GestureDetector(
          onTap: widget.onMicTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.isListening ? 72 : 64,
            height: widget.isListening ? 72 : 64,
            decoration: BoxDecoration(
              gradient: widget.isListening
                  ? const LinearGradient(
                      colors: [AppColors.error, Color(0xFFE55039)],
                    )
                  : AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.isListening
                          ? AppColors.error
                          : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: widget.isListening ? 20 : 12,
                  spreadRadius: widget.isListening ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Placeholder for symmetry
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        // Back to voice mode
        IconButton(
          onPressed: () => setState(() => _showTextField = false),
          icon: const Icon(Icons.mic_outlined),
          color: AppColors.primary,
          tooltip: 'Voice input',
        ),

        const SizedBox(width: 8),

        // Text field — SizedBox prevents negative baseline assertion on web
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _textController,
              autofocus: true,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Type your idea...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: _submitText,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send button
        IconButton(
          onPressed: () => _submitText(_textController.text),
          icon: const Icon(Icons.send_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }

  void _submitText(String text) {
    if (text.trim().isEmpty) return;
    widget.onTextSubmit?.call(text.trim());
    _textController.clear();
  }
}
