import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:table_calendar/table_calendar.dart';

/// Sticky compact calendar bar at the bottom of the main journal
/// screen. Renders a one-row week strip, a "Today" pill that fades in
/// when the user is off today, and a trailing icon that opens the
/// full-month bottom sheet.
///
/// When the soft keyboard is up the bar disappears (the editor body
/// needs the vertical real estate). The bar has a fixed height so the
/// Scaffold's `bottomNavigationBar` slot has a concrete intrinsic
/// height — `TableCalendar` doesn't provide one on its own.
class CalendarBottomBar extends StatelessWidget {
  const CalendarBottomBar({
    super.key,
    required this.selectedDate,
    required this.entriesByDay,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final Set<DateTime> entriesByDay;
  final ValueChanged<DateTime> onDateSelected;

  static const _kBarContentHeight = 56.0;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardUp) return const SizedBox.shrink();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: _kBarContentHeight + bottomInset,
      child: _Bar(
        selectedDate: selectedDate,
        entriesByDay: entriesByDay,
        onDateSelected: onDateSelected,
      ),
    );
  }
}

const EdgeInsets _kCellMargin = EdgeInsets.symmetric(
  horizontal: 2,
  vertical: 4,
);

/// Deterministic per-date colour from the post-it palette. Same date
/// always returns the same colour across rebuilds; the seed packs
/// y/m/d so neighbouring days don't visibly cycle through the palette
/// in order.
Color? _dayPaletteColor(DateTime day, List<String> paletteHex) {
  if (paletteHex.isEmpty) return null;
  final seed = day.year * 10000 + day.month * 100 + day.day;
  return colorFromHex(paletteHex[Random(seed).nextInt(paletteHex.length)]);
}

/// Resolves the colour for one calendar cell. When post-it mode is on,
/// uses the palette; otherwise falls back to scheme.primary so the
/// geometry (rounded-rect border / fill) still renders without the
/// palette being mandatory.
Color _cellColor(
  DateTime day,
  ThemeSettings themeSettings,
  ColorScheme scheme,
) {
  if (!themeSettings.postItModeEnabled) return scheme.primary;
  return _dayPaletteColor(day, themeSettings.postItPalette) ?? scheme.primary;
}

/// One styled day cell. Shared between the week strip and the month
/// sheet so styling stays in one place. Flags compose:
///
///   - `hasEntry && !isSelected` → rounded-rect border in the day's colour.
///   - `isToday && !isSelected`  → fill at 18% alpha (low-opacity).
///   - `isSelected`              → full fill, text uses [contrastOn].
///
/// Today + entry (not selected) shows both fill and border; selecting
/// today merges them into a single solid fill.
Widget _buildDayCell({
  required BuildContext context,
  required DateTime day,
  required bool isToday,
  required bool isSelected,
  required bool hasEntry,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final themeSettings = AppDependencies.of(context).themeSettings;
  final base = theme.textTheme.bodyMedium ?? const TextStyle();
  final dayColor = _cellColor(day, themeSettings, scheme);

  final Color? fill = isSelected
      ? dayColor
      : (isToday ? dayColor.withValues(alpha: 0.18) : null);
  final showBorder = hasEntry && !isSelected;

  final TextStyle textStyle;
  if (isSelected) {
    textStyle = base.copyWith(
      color: contrastOn(dayColor),
      fontWeight: FontWeight.w600,
    );
  } else if (isToday) {
    textStyle = base.copyWith(color: dayColor, fontWeight: FontWeight.w600);
  } else {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    textStyle = isWeekend
        ? base.copyWith(color: scheme.onSurfaceVariant)
        : base;
  }

  return Container(
    margin: _kCellMargin,
    decoration: BoxDecoration(
      color: fill,
      border: showBorder ? Border.all(color: dayColor, width: 1.5) : null,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text('${day.day}', style: textStyle),
  );
}

Widget _buildOutsideCell(BuildContext context, DateTime day) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final base = theme.textTheme.bodyMedium ?? const TextStyle();
  return Container(
    margin: _kCellMargin,
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: base.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.selectedDate,
    required this.entriesByDay,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final Set<DateTime> entriesByDay;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final debug = AppDependencies.of(context).debugSettings;
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isOnToday = isSameDay(selectedDate, today);
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _WeekStrip(
                  debug: debug,
                  selectedDate: selectedDate,
                  entriesByDay: entriesByDay,
                  onDateSelected: onDateSelected,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim,
                  axis: Axis.horizontal,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: isOnToday
                    ? const SizedBox.shrink(key: ValueKey('today-pill-empty'))
                    : Padding(
                        key: const ValueKey('today-pill'),
                        padding: const EdgeInsets.only(left: 4),
                        child: TextButton(
                          onPressed: () => onDateSelected(
                            CalendarBottomBar._normalize(today),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
              ),
              IconButton(
                tooltip: 'Open month view',
                onPressed: () => _openMonthSheet(context),
                icon: AppIcon(
                  HugeIcons.strokeRoundedCalendar01,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMonthSheet(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showDraggableSheet<DateTime>(
      context,
      initialChildSize: 0.6,
      minChildSize: 0.5,
      slivers: (ctx, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _MonthCalendar(
              debug: AppDependencies.of(ctx).debugSettings,
              selectedDate: selectedDate,
              entriesByDay: entriesByDay,
              onDateSelected: (date) {
                Navigator.of(ctx).pop(date);
              },
            ),
          ),
        ),
      ],
    );
    if (picked != null) onDateSelected(picked);
  }
}

class _WeekStrip extends StatefulWidget {
  const _WeekStrip({
    required this.debug,
    required this.selectedDate,
    required this.entriesByDay,
    required this.onDateSelected,
  });

  final DebugSettings debug;
  final DateTime selectedDate;
  final Set<DateTime> entriesByDay;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  late DateTime _focusedDay = _toUtcMidnight(widget.selectedDate);

  /// UTC-midnight representation of a date — matches what
  /// `TableCalendar` stores internally (its constructor calls
  /// `normalizeDate(focusedDay)`, which does exactly this).
  static DateTime _toUtcMidnight(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  /// Sunday-anchored start of the week containing [d]. Used as the
  /// key seed for [TableCalendar] so crossing a week boundary forces
  /// the calendar's internal `PageController` to be rebuilt from
  /// scratch with the correct `initialPage`. The package's own
  /// `didUpdateWidget → _updatePage → animateToPage` path is
  /// unreliable in practice — pushing a new `focusedDay` one week
  /// back didn't move the visible page (and tapping "Today" from
  /// another week didn't either), and the controller could land on
  /// a completely wrong page (we hit a "June 2033" symptom). A
  /// keyed remount sidesteps the package's internal animation state
  /// machine entirely: the new State's `initState` recomputes
  /// `initialPage` from the new `widget.focusedDay`, so the calendar
  /// always opens on the user's actual week.
  static DateTime _sundayOfWeek(DateTime d) {
    final n = _toUtcMidnight(d);
    // `weekday`: Monday=1, …, Saturday=6, Sunday=7.
    final delta = n.weekday == DateTime.sunday ? 0 : n.weekday;
    return n.subtract(Duration(days: delta));
  }

  @override
  void didUpdateWidget(covariant _WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _focusedDay = _toUtcMidnight(widget.selectedDate);
    }
  }

  bool _hasEntry(DateTime day) =>
      widget.entriesByDay.contains(CalendarBottomBar._normalize(day));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: widget.debug,
      builder: (context, _) {
        final firstDay = DateTime.utc(2000, 1, 1);
        final now = DateTime.now();
        final lastDay = widget.debug.unlockAllDays
            ? DateTime.utc(2100, 12, 31)
            : DateTime.utc(now.year, now.month, now.day);
        return TableCalendar(
          // Key on the Sunday of the visible week so the calendar's
          // internal State (including its `PageController`) is
          // recreated whenever the user crosses a week boundary —
          // see `_sundayOfWeek` for why.
          key: ValueKey(
            'week-${_sundayOfWeek(widget.selectedDate).toIso8601String()}',
          ),
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          availableCalendarFormats: const {CalendarFormat.week: 'Week'},
          headerVisible: false,
          daysOfWeekVisible: false,
          rowHeight: 44,
          selectedDayPredicate: (d) => isSameDay(d, widget.selectedDate),
          onDaySelected: (selected, focused) {
            setState(() => _focusedDay = focused);
            widget.onDateSelected(selected);
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: false,
              isSelected: false,
              hasEntry: _hasEntry(day),
            ),
            todayBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: true,
              isSelected: false,
              hasEntry: _hasEntry(day),
            ),
            selectedBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: true,
              hasEntry: _hasEntry(day),
            ),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: _kCellMargin,
            defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            weekendTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.onSurfaceVariant),
            outsideTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
          ),
        );
      },
    );
  }
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.debug,
    required this.selectedDate,
    required this.entriesByDay,
    required this.onDateSelected,
  });

  final DebugSettings debug;
  final DateTime selectedDate;
  final Set<DateTime> entriesByDay;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _focusedDay = _WeekStripState._toUtcMidnight(
    widget.selectedDate,
  );

  bool _hasEntry(DateTime day) =>
      widget.entriesByDay.contains(CalendarBottomBar._normalize(day));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: widget.debug,
      builder: (context, _) {
        final firstDay = DateTime.utc(2000, 1, 1);
        final now = DateTime.now();
        final lastDay = widget.debug.unlockAllDays
            ? DateTime.utc(2100, 12, 31)
            : DateTime.utc(now.year, now.month, now.day);
        return TableCalendar(
          // Key on the year/month of the externally-selected day so the
          // calendar's State is rebuilt with a fresh `PageController`
          // when the selection moves to a different month. Internal
          // chevron / swipe navigation does NOT change `selectedDate`,
          // so the Key stays stable and the user's in-sheet navigation
          // animates normally. Mirrors the same workaround the week
          // strip uses — see `_WeekStripState._sundayOfWeek` for why.
          key: ValueKey(
            'month-${widget.selectedDate.year}-'
            '${widget.selectedDate.month.toString().padLeft(2, '0')}',
          ),
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          selectedDayPredicate: (d) => isSameDay(d, widget.selectedDate),
          onDaySelected: (selected, focused) {
            setState(() => _focusedDay = focused);
            widget.onDateSelected(selected);
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle:
                theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(color: scheme.onSurface),
            leftChevronIcon: AppIcon(
              HugeIcons.strokeRoundedArrowLeft01,
              color: scheme.onSurface,
            ),
            rightChevronIcon: AppIcon(
              HugeIcons.strokeRoundedArrowRight01,
              color: scheme.onSurface,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: false,
              isSelected: false,
              hasEntry: _hasEntry(day),
            ),
            todayBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: true,
              isSelected: false,
              hasEntry: _hasEntry(day),
            ),
            selectedBuilder: (ctx, day, _) => _buildDayCell(
              context: ctx,
              day: day,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: true,
              hasEntry: _hasEntry(day),
            ),
            outsideBuilder: (ctx, day, _) => _buildOutsideCell(ctx, day),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: _kCellMargin,
            defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            weekendTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.onSurfaceVariant),
          ),
        );
      },
    );
  }
}
