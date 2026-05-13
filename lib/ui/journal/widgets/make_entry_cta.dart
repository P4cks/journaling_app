import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Centered call-to-action shown on the main journal screen for days
/// that don't yet have an entry (today). Tapping fires [onTap] —
/// typically opens the layout picker.
class MakeEntryCta extends StatelessWidget {
  const MakeEntryCta({
    super.key,
    required this.onTap,
    this.title = 'No entry yet',
    this.subtitle = 'Start journaling — pick a layout to begin.',
    this.buttonLabel = 'Make entry',
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              PhosphorIconsDuotone.notePencil,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onTap,
              icon: const AppIcon(PhosphorIconsBold.plus),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
