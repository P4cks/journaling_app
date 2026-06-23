import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Centered message shown for a past day that never had an entry — the
/// user cannot create one (the day is locked) and there is nothing to
/// preview, so the body just explains the state, quietly (GUS-87).
class NoEntryReadOnly extends StatelessWidget {
  const NoEntryReadOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(HugeIcons.strokeRoundedCalendar03, size: 36, color: muted),
            const SizedBox(height: 14),
            Text(
              'Nothing written this day',
              style: theme.textTheme.titleMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
