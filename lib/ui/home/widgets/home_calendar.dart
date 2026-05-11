import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

/// Sentinel marker passed back via `eventLoader`. `TableCalendar` only
/// looks at list length when deciding whether to paint a dot, so the
/// element value is irrelevant — `const Object()` keeps allocation flat.
const _kHasEntryMarker = Object();
const _kHasEntry = <Object>[_kHasEntryMarker];
const _kNoEntries = <Object>[];

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  CalendarFormat _format = CalendarFormat.week;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final debug = AppDependencies.of(context).debugSettings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final defaultTextStyle = theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ) ??
        TextStyle(color: scheme.onSurface);
    final mutedTextStyle = defaultTextStyle.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final disabledTextStyle = defaultTextStyle.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
    );

    return ListenableBuilder(
      listenable: debug,
      builder: (context, _) {
        final firstDay = DateTime.utc(2000, 1, 1);
        final now = DateTime.now();
        final lastDay = debug.unlockAllDays
            ? DateTime.utc(2100, 12, 31)
            : DateTime.utc(now.year, now.month, now.day);

        return TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: widget.viewModel.focusedDate,
          selectedDayPredicate: (day) =>
              isSameDay(day, widget.viewModel.selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            widget.viewModel.selectDate(selectedDay);
          },
          onPageChanged: widget.viewModel.updateFocusedDate,
          calendarFormat: _format,
          onFormatChanged: (fmt) {
            if (fmt == _format) return;
            debugPrint('[HomeCalendar] format -> $fmt');
            setState(() => _format = fmt);
          },
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.week: 'Week',
          },
          availableGestures: AvailableGestures.all,
          eventLoader: (day) =>
              widget.viewModel.entriesByDay.contains(_normalize(day))
                  ? _kHasEntry
                  : _kNoEntries,
          calendarStyle: CalendarStyle(
            // Day cells
            defaultTextStyle: defaultTextStyle,
            weekendTextStyle: mutedTextStyle,
            outsideTextStyle: disabledTextStyle,
            disabledTextStyle: disabledTextStyle,
            holidayTextStyle: defaultTextStyle,
            // Selected day — filled accent
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: defaultTextStyle.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            // Today — outlined accent (lets selection still pop on top)
            todayDecoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            todayTextStyle: defaultTextStyle.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
            // Entry-existence marker (tuned in PR #6)
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 1,
            // Cell padding stays default; row/col separators inherit.
            cellMargin: const EdgeInsets.all(4),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            titleTextStyle: theme.textTheme.titleMedium?.copyWith(
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
            formatButtonDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outline),
            ),
            formatButtonTextStyle: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ) ??
                TextStyle(color: scheme.onSurfaceVariant),
            formatButtonPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: mutedTextStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
            weekendStyle: mutedTextStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
