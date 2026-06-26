/// Action step card — a single step in the 3-step action plan.
library;


import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/brainstorm_result.dart';

class ActionStepCard extends StatelessWidget {

  const ActionStepCard({super.key, required this.step});
  final ActionStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
