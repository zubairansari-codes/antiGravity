/// Alternatives section — displays alternative angles on the result screen.
library;


import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AlternativesSection extends StatelessWidget {

  const AlternativesSection({super.key, required this.alternatives});
  final List<String> alternatives;

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alternative Angles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...alternatives.map((alt) => _AlternativeCard(text: alt)),
      ],
    );
  }
}

class _AlternativeCard extends StatelessWidget {

  const _AlternativeCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.alt_route_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
