/// Voice wave animation — visual feedback during listening/speaking.
///
/// Shows 5 animated bars that pulse in a staggered wave pattern.
/// Active colour changes based on whether the app is listening
/// (primary purple) or speaking (amber accent).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class VoiceWaveAnimation extends StatefulWidget {
  final bool isActive;
  final bool isSpeaking;

  const VoiceWaveAnimation({
    super.key,
    required this.isActive,
    required this.isSpeaking,
  });

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive || widget.isSpeaking;
    final color = widget.isSpeaking
        ? AppColors.waveSpeaking
        : widget.isActive
            ? AppColors.waveActive
            : AppColors.waveIdle;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (index) {
              // Stagger each bar by a phase offset.
              final phase = index * 0.2;
              final value = isActive
                  ? (math.sin((_controller.value + phase) * 2 * math.pi)
                              .abs() *
                          0.6 +
                      0.4)
                  : 0.3;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 6,
                height: 60 * value,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(isActive ? 1.0 : 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
