import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Page-level (or per-chart) empty state for the statistics page.
class StatsEmptyState extends StatelessWidget {
  const StatsEmptyState({
    super.key,
    this.message = 'No entries in this range',
    this.compact = false,
  });

  final String message;

  /// When true, renders a smaller inline empty state suitable for
  /// dropping into a single chart's placeholder slot.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSize = compact ? 32.0 : 56.0;
    final padding = compact
        ? const EdgeInsets.symmetric(vertical: 24, horizontal: 16)
        : const EdgeInsets.all(24);
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HugeIcons.strokeRoundedChartBarLine,
              size: iconSize,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: compact ? 8 : 16),
            Text(
              message,
              style: (compact
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
