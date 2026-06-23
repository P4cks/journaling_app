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
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/tonal.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_or_emoji.dart';

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
        // The stored value is an icon name or an emoji glyph (GUS-82);
        // `_HabitCheckBubble` disambiguates via `IconOrEmoji`. Null / empty /
        // unknown all fall back to the default check glyph.
        final iconValue = definition?.iconName;

        final stats = defId == null
            ? null
            : _computeStats(repo, defId, content.completed);
        final streak = stats?.streak ?? 0;

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
                    iconValue: iconValue,
                    size: 56,
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (streak > 0) ...[
                          _StreakBadge(count: streak),
                          const SizedBox(width: 8),
                        ],
                        _SevenDayStrip(
                          completedDays: stats.completedDays,
                          anchor: stats.anchor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Single scan over every entry, yielding both the set of days this
  /// habit was crossed off and this block's anchor day, then the derived
  /// streak. The streak counts consecutive completed days ending at the
  /// anchor (inclusive when the anchor is crossed off; otherwise the run
  /// ending the day before — so it still shows momentum about to be lost).
  /// Both the streak badge and the 7-day strip read from this one scan.
  ///
  /// `liveCompleted` is this block's in-hand `completed` value, used to
  /// reflect an unsaved toggle for the anchor day before storage catches
  /// up.
  _HabitStats _computeStats(
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
    return _HabitStats(
      streak: streak,
      completedDays: completedDays,
      anchor: anchor,
    );
  }
}

/// Result of the one entry scan in [HabitTrackerWidget._computeStats]:
/// the derived [streak], the set of normalized days the habit was crossed
/// off ([completedDays]), and this block's [anchor] day. The strip and the
/// streak badge both consume this so the entry walk happens only once.
class _HabitStats {
  const _HabitStats({
    required this.streak,
    required this.completedDays,
    required this.anchor,
  });

  final int streak;
  final Set<DateTime> completedDays;
  final DateTime anchor;
}

/// Read-only strip of the 7 days ending on (and including) the block's
/// [anchor] day, oldest → newest. A day is ticked when it is in
/// [completedDays]. Display only — the big bubble is the sole toggle, so
/// the strip never writes across entries. Scaled down to fit narrow grid
/// cells via [FittedBox].
class _SevenDayStrip extends StatelessWidget {
  const _SevenDayStrip({required this.completedDays, required this.anchor});

  final Set<DateTime> completedDays;
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(anchor.year, anchor.month, anchor.day - i),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _DayDot(checked: completedDays.contains(days[i])),
          ],
        ],
      ),
    );
  }
}

/// One day indicator in the [_SevenDayStrip]: a small filled tick when
/// checked, a faint bordered circle when not.
class _DayDot extends StatelessWidget {
  const _DayDot({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final ink = blockInk(context);
    const size = 14.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? ink : Colors.transparent,
        border: Border.all(
          color: checked ? ink : ink.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: checked
          ? Center(
              child: AppIcon(
                HugeIcons.strokeRoundedTick01,
                size: size * 0.6,
                color: contrastOn(ink),
              ),
            )
          : null,
    );
  }
}

/// The big cross-off control. Empty → bordered circle with the habit's
/// icon or emoji (GUS-82) faintly inside. Done → filled primary circle with
/// a tick. [iconValue] is the stored icon name / emoji glyph (null / empty /
/// unknown → default check glyph).
class _HabitCheckBubble extends StatelessWidget {
  const _HabitCheckBubble({
    required this.completed,
    required this.iconValue,
    required this.size,
  });

  final bool completed;
  final String? iconValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Track the chrome-injected tonal ink (GUS-86): a filled ink bubble when
    // completed (tick in the ink's contrast colour), a muted ink ring + glyph
    // when not.
    final ink = blockInk(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? ink : Colors.transparent,
        border: Border.all(
          color: completed ? ink : ink.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: completed
            ? AppIcon(
                HugeIcons.strokeRoundedTick01,
                size: size * 0.5,
                color: contrastOn(ink),
              )
            : IconOrEmoji(
                value: iconValue,
                resolveIcon: (v) => (v == null || v.isEmpty)
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : (carouselIconFor(v)?.icon ??
                          HugeIcons.strokeRoundedCheckmarkCircle02),
                size: size * 0.5,
                color: ink.withValues(alpha: 0.7),
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
    final ink = blockInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(HugeIcons.strokeRoundedFire, size: 14, color: ink),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
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
