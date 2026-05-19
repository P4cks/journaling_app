import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Full-width card pinned at the top of the entries `CustomScrollView`.
/// Shows the user's current and longest streaks side-by-side, or a
/// nudge when there's no current streak yet.
class StreakStatCard extends StatelessWidget {
  const StreakStatCard({super.key, required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: streak.current == 0
            ? _NudgeRow(streak: streak)
            : _StatsRow(streak: streak),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatColumn(
            label: 'Current',
            value: streak.current,
            isActive: true,
          ),
        ),
        Container(
          width: 1,
          height: 44,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: _StatColumn(
            label: 'Best',
            value: streak.longest,
            isActive: false,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.isActive,
  });

  final String label;
  final int value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HugeIcons.strokeRoundedFire,
              size: 20,
              color: isActive
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NudgeRow extends StatelessWidget {
  const _NudgeRow({required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasHistory = streak.longest > 0;
    final message = hasHistory
        ? 'Make an entry today to start a new streak. Best so far: '
              '${streak.longest} days.'
        : 'Make an entry today to start a streak.';
    return Row(
      children: [
        AppIcon(HugeIcons.strokeRoundedFire, size: 28, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
