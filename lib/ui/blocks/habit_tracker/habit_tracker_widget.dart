import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/habit_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_with_title.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Block widget for a `BlockType.habitTracker` instance. Resolves
/// `definitionId` against the `BlockSettings` registry for the habit's
/// title + icon, renders a big cross-off checkbox, and surfaces the
/// current streak (flame + count) computed by scanning every entry that
/// shares the same `definitionId`.
///
/// - **Found definition**: big checkbox (tap to toggle `completed`),
///   habit title above (via [BlockWithTitle]), flame + streak below
///   when the streak is > 0.
/// - **`definitionId == null`** (preview / sample only — real
///   materialized blocks always carry a slot's definitionId): a generic
///   checkbox with no title and no streak.
/// - **Missing definition** (deleted out from under the block): dimmed
///   "Deleted block" placeholder. Existing entries keep their logged
///   `completed` flag on disk regardless.
///
/// Subscribes to both `BlockSettings` (definition edits) and
/// `JournalRepository` (so the streak recomputes when other days change).
class HabitTrackerWidget extends StatelessWidget {
  const HabitTrackerWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final VoidCallback? onDoubleTap;
  final bool editing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final repo = deps.journalRepository;

    return ListenableBuilder(
      listenable: Listenable.merge([settings, repo]),
      builder: (context, _) {
        final content = HabitBlockContent.fromMap(data.content);
        final defId = content.definitionId;

        // Orphan: the definition was deleted. Keep the entry's logged
        // state on disk but render a placeholder (nothing to interact
        // with). `null` defId is the preview/sample path, not an orphan.
        if (defId != null && settings.findHabit(defId) == null) {
          return const _DeletedPlaceholder();
        }

        final definition = defId == null ? null : settings.findHabit(defId);
        final title = definition?.title;
        final iconData = definition == null
            ? HugeIcons.strokeRoundedCheckmarkCircle02
            : (carouselIconFor(definition.iconName)?.icon ??
                  HugeIcons.strokeRoundedCheckmarkCircle02);

        final streak = defId == null
            ? 0
            : _computeStreak(repo, defId, content.completed);

        final interactive = mode != BlockMode.readOnly && onChanged != null;

        return BlockWithTitle(
          title: title,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: interactive
                ? () => onChanged!.call(
                    data.copyWith(
                      content: HabitBlockContent(
                        definitionId: content.definitionId,
                        completed: !content.completed,
                      ).toMap(),
                    ),
                  )
                : null,
            onDoubleTap: onDoubleTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HabitCheckBubble(
                    completed: content.completed,
                    icon: iconData,
                    size: 56,
                  ),
                  if (streak > 0) ...[
                    const SizedBox(height: 8),
                    _StreakBadge(count: streak),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Count of consecutive completed days for this habit definition,
  /// ending at this block's own entry date (inclusive when today is
  /// crossed off; otherwise the run ending the day before — so the
  /// streak still shows momentum the user is about to lose).
  ///
  /// `liveCompleted` is this block's in-hand `completed` value, used to
  /// reflect an unsaved toggle for the anchor day before storage catches
  /// up.
  int _computeStreak(
    JournalRepository repo,
    String defId,
    bool liveCompleted,
  ) {
    final completedDays = <DateTime>{};
    DateTime? anchor;
    for (final entry in repo.getAllEntries()) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      for (final section in entry.sections) {
        for (final block in section.blocks) {
          if (block.id == data.id) anchor = day;
          if (block.type != BlockType.habitTracker) continue;
          final c = HabitBlockContent.fromMap(block.content);
          if (c.definitionId == defId && c.completed) {
            completedDays.add(day);
          }
        }
      }
    }

    final now = DateTime.now();
    anchor ??= DateTime(now.year, now.month, now.day);

    // Reflect the live (possibly unsaved) toggle for the anchor day.
    if (liveCompleted) {
      completedDays.add(anchor);
    } else {
      completedDays.remove(anchor);
    }

    var cursor = completedDays.contains(anchor)
        ? anchor
        : DateTime(anchor.year, anchor.month, anchor.day - 1);
    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }
}

/// The big cross-off control. Empty → bordered circle with the habit's
/// icon faintly inside. Done → filled primary circle with a tick.
class _HabitCheckBubble extends StatelessWidget {
  const _HabitCheckBubble({
    required this.completed,
    required this.icon,
    required this.size,
  });

  final bool completed;
  final HugeIconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: completed ? scheme.primary : scheme.outline,
          width: 2,
        ),
      ),
      child: Center(
        child: AppIcon(
          completed ? HugeIcons.strokeRoundedTick01 : icon,
          size: size * 0.5,
          color: completed
              ? scheme.onPrimary
              : scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Flame + streak count, shown only when the streak is > 0.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          HugeIcons.strokeRoundedFire,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DeletedPlaceholder extends StatelessWidget {
  const _DeletedPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Deleted block',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
