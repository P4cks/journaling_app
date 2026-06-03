import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

class SummaryNumbersCard extends StatelessWidget {
  const SummaryNumbersCard({
    super.key,
    required this.totalEntries,
    required this.totalWords,
    required this.totalMoodEntries,
    required this.currentStreak,
  });

  final int totalEntries;
  final int totalWords;
  final int totalMoodEntries;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _Cell(
                icon: HugeIcons.strokeRoundedBookOpen01,
                label: 'Entries',
                value: totalEntries,
              ),
            ),
            _Divider(),
            Expanded(
              child: _Cell(
                icon: HugeIcons.strokeRoundedTextFont,
                label: 'Words',
                value: totalWords,
              ),
            ),
            _Divider(),
            Expanded(
              child: _Cell(
                icon: HugeIcons.strokeRoundedSmile,
                label: 'Moods',
                value: totalMoodEntries,
              ),
            ),
            _Divider(),
            Expanded(
              child: _Cell(
                icon: HugeIcons.strokeRoundedFire,
                label: 'Streak',
                value: currentStreak,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.icon, required this.label, required this.value});

  final HugeIconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 22, color: scheme.primary),
        const SizedBox(height: 6),
        Text(
          _formatCount(value),
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n < 1000) return n.toString();
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}k';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
