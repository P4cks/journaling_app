import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required JournalRepository journalRepository,
    DateTime? initialDate,
  })  : _repository = journalRepository,
        _selectedDate = _dateOnly(initialDate ?? DateTime.now()),
        _focusedDate = _dateOnly(initialDate ?? DateTime.now()) {
    debugPrint('[HomeViewModel] init selectedDate=$_selectedDate');
    _loadEntry();
  }

  final JournalRepository _repository;

  DateTime _selectedDate;
  DateTime _focusedDate;
  JournalEntry? _currentEntry;

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  JournalEntry? get currentEntry => _currentEntry;

  void selectDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_selectedDate == normalized) {
      debugPrint('[HomeViewModel] selectDate ignored (unchanged $normalized)');
      return;
    }
    debugPrint(
      '[HomeViewModel] selectDate $_selectedDate -> $normalized',
    );
    _selectedDate = normalized;
    _focusedDate = normalized;
    _loadEntry();
    notifyListeners();
  }

  void reload() {
    debugPrint('[HomeViewModel] reload for $_selectedDate');
    _loadEntry();
    notifyListeners();
  }

  void updateFocusedDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_focusedDate == normalized) return;
    debugPrint(
      '[HomeViewModel] updateFocusedDate $_focusedDate -> $normalized',
    );
    _focusedDate = normalized;
  }

  void _loadEntry() {
    final entry = _repository.getOrCreateEntryForDate(_selectedDate);
    debugPrint('[HomeViewModel] loaded $entry');
    _currentEntry = entry;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
