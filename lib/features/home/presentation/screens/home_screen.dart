/// Home screen — lists past brainstorms with search, filters, and a FAB to start a new session.
library;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/error_view.dart';
import '../../../../core/widgets/feedback/loading_spinner.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../providers/home_viewmodel.dart';
import '../providers/settings_providers.dart';
import '../widgets/brainstorm_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _CategorySelectionSheet(),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Brainstorm'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                HapticFeedback.lightImpact();
                ref.read(homeViewModelProvider.notifier).renameBrainstorm(id, newTitle);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filteredBrainstormsProvider);
    final searchQuery = ref.watch(homeSearchQueryProvider);
    final categoryFilter = ref.watch(homeCategoryFilterProvider);
    final dailyCountAsync = ref.watch(dailyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_rounded,
                color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'AntiGravity',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(homeSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search brainstorms...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(homeSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: categoryFilter == null,
                  onSelected: (_) =>
                      ref.read(homeCategoryFilterProvider.notifier).state = null,
                ),
                ...BrainstormCategory.values.map((category) {
                  return _FilterChip(
                    label: category.label,
                    selected: categoryFilter == category,
                    onSelected: (_) => ref
                        .read(homeCategoryFilterProvider.notifier)
                        .state = category,
                  );
                }),
              ],
            ),
          ),

          // Daily usage indicator
          dailyCountAsync.when(
            data: (count) => _DailyUsageIndicator(count: count),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Brainstorm list
          Expanded(
            child: state.when(
              data: (brainstorms) => brainstorms.isEmpty
                  ? _EmptyState(
                      hasFilters: searchQuery.isNotEmpty || categoryFilter != null,
                    )
                  : BrainstormList(
                      brainstorms: brainstorms,
                      onTap: (id) {
                        final brainstorm =
                            brainstorms.firstWhere((b) => b.id == id);
                        if (brainstorm.isComplete && brainstorm.result != null) {
                          context.push('/result', extra: brainstorm.result);
                        }
                      },
                      onDelete: (id) {
                        ref
                            .read(homeViewModelProvider.notifier)
                            .deleteBrainstorm(id);
                      },
                      onRename: (id) {
                        final brainstorm = brainstorms.firstWhere((b) => b.id == id);
                        _showRenameDialog(context, brainstorm.id, brainstorm.title);
                      },
                      onToggleFavorite: (id) {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favorites coming soon!')),
                        );
                      },
                    ),
              loading: () => const LoadingSpinner(message: 'Loading sessions...'),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.read(homeViewModelProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryPicker(context),
        icon: const Icon(Icons.mic_rounded),
        label: const Text(
          'New Brainstorm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {

  const _FilterChip({
    required this.label,
    required this.selected,
    this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
    );
  }
}

class _DailyUsageIndicator extends StatelessWidget {

  const _DailyUsageIndicator({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.freeBrainstormsPerDay - count;
    final isAtLimit = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAtLimit
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAtLimit
                ? AppColors.error.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAtLimit ? Icons.lock_outline : Icons.local_fire_department,
              size: 16,
              color: isAtLimit ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAtLimit
                    ? 'Daily limit reached — upgrade for unlimited sessions'
                    : '$remaining/${AppConstants.freeBrainstormsPerDay} free brainstorms left today',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAtLimit ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {

  const _EmptyState({this.hasFilters = false});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    if (hasFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your search or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient icon
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Think out loud.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tap the mic to start your first\nbrainstorming session with AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Feature pills
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _FeaturePill(
                    icon: Icons.swap_horiz, label: 'Explore inverses'),
                _FeaturePill(
                    icon: Icons.checklist, label: 'Get action plans'),
                _FeaturePill(
                    icon: Icons.auto_awesome, label: 'Ready prompts'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {

  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelectionSheet extends StatelessWidget {
  const _CategorySelectionSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a Persona',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Who do you want to brainstorm with?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...BrainstormCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  context.pop();
                  context.push('/brainstorm', extra: category);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(category.icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
