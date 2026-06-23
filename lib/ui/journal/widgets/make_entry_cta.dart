import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Centered call-to-action shown on the main journal screen for days
/// that don't yet have an entry (today). Tapping fires [onTap] —
/// typically opens the layout picker. A null [onTap] renders the
/// button disabled.
class MakeEntryCta extends StatelessWidget {
  const MakeEntryCta({
    super.key,
    required this.onTap,
    this.title = 'A blank page',
    this.subtitle = 'Start today’s entry — pick a layout and begin.',
    this.buttonLabel = 'Make entry',
  });

  final VoidCallback? onTap;
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
            // Soft accent halo behind the glyph — a warm, inviting focal point
            // rather than a cold grey icon (GUS-87).
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.10),
              ),
              child: AppIcon(
                HugeIcons.strokeRoundedNoteEdit,
                size: 44,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: onTap,
              icon: HugeIcons.strokeRoundedPlusSign,
              label: buttonLabel,
            ),
          ],
        ),
      ),
    );
  }
}
