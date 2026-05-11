import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 1,
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
        );
      },
    );
  }
}
