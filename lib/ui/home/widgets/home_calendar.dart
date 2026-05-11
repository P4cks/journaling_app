import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final debug = AppDependencies.of(context).debugSettings;
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
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
        );
      },
    );
  }
}
