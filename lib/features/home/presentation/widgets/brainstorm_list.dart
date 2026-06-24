/// Brainstorm list — displays past sessions on the home screen with rename and favorite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_category.dart';

class BrainstormList extends StatelessWidget {
  final List<Brainstorm> brainstorms;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onRename;
  final ValueChanged<String>? onToggleFavorite;

  const BrainstormList({
    super.key,
    required this.brainstorms,
    this.onTap,
    this.onDelete,
    this.onRename,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: brainstorms.length,
      itemBuilder: (context, index) {
        final brainstorm = brainstorms[index];
        return Semantics(
          label:
              'Brainstorm about ${brainstorm.title}, ${brainstorm.createdAt.formatted}',
          button: true,
          child: _BrainstormCard(
            brainstorm: brainstorm,
            onTap: () => onTap?.call(brainstorm.id),
            onDelete: () => onDelete?.call(brainstorm.id),
            onRename: () => onRename?.call(brainstorm.id),
            onToggleFavorite: () => onToggleFavorite?.call(brainstorm.id),
          ),
        );
      },
    );
  }
}

class _BrainstormCard extends StatelessWidget {
  final Brainstorm brainstorm;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onToggleFavorite;

  const _BrainstormCard({
    required this.brainstorm,
    this.onTap,
    this.onDelete,
    this.onRename,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(brainstorm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExcludeSemantics(
          child: Icon(Icons.delete_outline, color: AppColors.error),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status badge + actions
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        brainstorm.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (brainstorm.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✓ Complete',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Preview
                Text(
                  brainstorm.preview,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Metadata row
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${brainstorm.messages.length} messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      brainstorm.createdAt.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.of(context).pop();
                  onRename?.call();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star_border,
                  color: AppColors.accent,
                ),
                title: const Text('Favorite'),
                onTap: () {
                  Navigator.of(context).pop();
                  onToggleFavorite?.call();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
