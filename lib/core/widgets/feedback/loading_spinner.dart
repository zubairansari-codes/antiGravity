// Reusable loading spinner.
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
