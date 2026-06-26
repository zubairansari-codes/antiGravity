/// Risk card — displays the riskiest assumption on the result screen.
library;


import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RiskCard extends StatelessWidget {

  const RiskCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Riskiest Assumption',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
