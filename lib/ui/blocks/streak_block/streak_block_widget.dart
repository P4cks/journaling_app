import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Display-only block that shows the streak **as of its own entry's date**
/// prominently, with the best streak up to that date in small text
/// beneath it.
///
/// The block stores no per-entry content — instead it self-locates the
/// entry that hosts it (by matching [JournalBlockData.id] against
/// [JournalRepository.getAllEntries]) and computes the streak *as of that
/// entry's date*, so each day shows its own streak length (July 1 → 1 day,
/// July 2 → 2 days, …) rather than today's streak echoed across every day.
/// It rebuilds through a [ListenableBuilder] so the numbers update the
/// instant a new entry lands. When the block isn't part of any saved entry
/// (e.g. the layout-editor preview) it falls back to the live, today-anchored
/// streak. It is unlocked for **everyone** (free and Pro) at the 7-day
/// streak milestone — see
/// [StreakRewardSettings](../../../data/services/streak_reward_settings.dart).
class StreakBlockWidget extends StatelessWidget {
  const StreakBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onDoubleTap,
  });

  final JournalBlockData data;
  final BlockMode mode;

  /// Host's "push expanded route" callback — fires on double-tap.
  /// Streak has no single-tap engage (display-only block).
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final repository = AppDependencies.of(context).journalRepository;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListenableBuilder(
          listenable: repository,
          builder: (context, _) {
            final entries = repository.getAllEntries();
            final asOf = _entryDateFor(entries, data.id);
            final streak = asOf == null
                // Not part of any saved entry (e.g. layout-editor preview):
                // show the live, today-anchored streak.
                ? computeStreak(entries)
                // Scope to days up to and including this entry's date so both
                // the current run and the best run read "as of that day".
                : computeStreak(
                    entries
                        .where((e) => !_normalizeDay(e.date).isAfter(asOf))
                        .toList(),
                    now: asOf,
                  );
            return _StreakBody(streak: streak);
          },
        ),
      ),
    );
  }
}

/// Find the local-midnight date of the entry that hosts the block with
/// [blockId], or `null` when no saved entry contains it.
DateTime? _entryDateFor(List<JournalEntry> entries, String blockId) {
  for (final entry in entries) {
    for (final section in entry.sections) {
      for (final block in section.blocks) {
        if (block.id == blockId) return _normalizeDay(entry.date);
      }
    }
  }
  return null;
}

DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

class _StreakBody extends StatelessWidget {
  const _StreakBody({required this.streak});

  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedFire,
                  size: 30,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  streak.current.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'day streak',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${streak.longest} ${streak.longest == 1 ? 'day' : 'days'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
