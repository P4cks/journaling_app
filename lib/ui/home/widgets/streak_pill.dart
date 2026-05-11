import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Compact pill rendered above the calendar showing the user's current
/// journaling streak. Tapping it navigates to the Entries tab so the
/// user can drill into the full stat card and entry history.
///
/// Hidden by the parent when both [StreakResult.current] and
/// [StreakResult.longest] are zero — no point pestering a brand-new user.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.streak, this.onTap});

  final StreakResult streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCurrent = streak.current > 0;
    final label = hasCurrent
        ? '${streak.current}-day streak'
        : 'Best: ${streak.longest} days';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    hasCurrent
                        ? PhosphorIconsFill.flame
                        : PhosphorIconsDuotone.flame,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                    secondaryColor: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
