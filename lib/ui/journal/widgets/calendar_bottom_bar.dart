import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

/// `TableCalendar.eventLoader` sentinel — the package only checks list
/// length when deciding whether to paint a dot, so a `const Object()`
/// keeps allocation flat.
const _kHasEntryMarker = Object();
const _kHasEntry = <Object>[_kHasEntryMarker];
const _kNoEntries = <Object>[];

/// Sticky compact calendar bar at the bottom of the main journal
/// screen. Replaces the bottom navigation. Renders a one-row week
/// strip; a trailing icon opens a full-month bottom sheet.
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
              IconButton(
                tooltip: 'Open month view',
                onPressed: () => _openMonthSheet(context),
                icon: AppIcon(
                  PhosphorIconsDuotone.calendarBlank,
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
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MonthCalendar(
                    debug: AppDependencies.of(ctx).debugSettings,
                    selectedDate: selectedDate,
                    entriesByDay: entriesByDay,
                    onDateSelected: (date) {
                      Navigator.of(ctx).pop(date);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
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
  late DateTime _focusedDay = widget.selectedDate;

  @override
  void didUpdateWidget(covariant _WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _focusedDay = widget.selectedDate;
    }
  }

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
          eventLoader: (day) =>
              widget.entriesByDay.contains(CalendarBottomBar._normalize(day))
              ? _kHasEntry
              : _kNoEntries,
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            weekendTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.onSurfaceVariant),
            outsideTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
            todayDecoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            todayTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 4,
            markersMaxCount: 1,
            markersAlignment: Alignment.bottomCenter,
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
  late DateTime _focusedDay = widget.selectedDate;

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
          eventLoader: (day) =>
              widget.entriesByDay.contains(CalendarBottomBar._normalize(day))
              ? _kHasEntry
              : _kNoEntries,
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
              PhosphorIconsDuotone.caretLeft,
              color: scheme.onSurface,
            ),
            rightChevronIcon: AppIcon(
              PhosphorIconsDuotone.caretRight,
              color: scheme.onSurface,
            ),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
            todayDecoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            todayTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 1,
          ),
        );
      },
    );
  }
}
