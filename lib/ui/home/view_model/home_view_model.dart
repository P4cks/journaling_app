import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({DateTime? initialDate})
      : _selectedDate = _dateOnly(initialDate ?? DateTime.now()),
        _focusedDate = _dateOnly(initialDate ?? DateTime.now());

  DateTime _selectedDate;
  DateTime _focusedDate;

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;

  void selectDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    _focusedDate = normalized;
    notifyListeners();
  }

  void updateFocusedDate(DateTime date) {
    _focusedDate = _dateOnly(date);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
