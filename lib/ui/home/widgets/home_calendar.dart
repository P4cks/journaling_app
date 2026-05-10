import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeCalendar extends StatelessWidget {
  const HomeCalendar({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.utc(2000, 1, 1);
    final lastDay = DateTime.utc(2100, 12, 31);

    return TableCalendar(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: viewModel.focusedDate,
      selectedDayPredicate: (day) => isSameDay(day, viewModel.selectedDate),
      onDaySelected: (selectedDay, focusedDay) {
        viewModel.selectDate(selectedDay);
      },
      onPageChanged: viewModel.updateFocusedDate,
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}
