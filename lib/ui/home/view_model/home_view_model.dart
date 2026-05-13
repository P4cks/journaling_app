import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required JournalRepository journalRepository,
    DateTime? initialDate,
  }) : _repository = journalRepository,
       _selectedDate = _dateOnly(initialDate ?? DateTime.now()),
       _focusedDate = _dateOnly(initialDate ?? DateTime.now()) {
    debugPrint('[HomeViewModel] init selectedDate=$_selectedDate');
    _repository.addListener(_onRepositoryChanged);
    _loadEntry();
    _recomputeEntriesByDay();
  }

  final JournalRepository _repository;

  DateTime _selectedDate;
  DateTime _focusedDate;
  JournalEntry? _currentEntry;
  Set<DateTime> _entriesByDay = const <DateTime>{};

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  JournalEntry? get currentEntry => _currentEntry;

  /// Set of normalized (local-midnight) days that currently have an entry.
  /// Drives the calendar dot indicator. Empty entries are *included* here —
  /// the user has clicked "Make entry" for today, so the day deserves a
  /// dot. Past-day empties get swept by the repository so they'll drop out
  /// of this set on the next notification.
  Set<DateTime> get entriesByDay => _entriesByDay;

  void selectDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_selectedDate == normalized) {
      debugPrint('[HomeViewModel] selectDate ignored (unchanged $normalized)');
      return;
    }
    debugPrint('[HomeViewModel] selectDate $_selectedDate -> $normalized');
    _selectedDate = normalized;
    _focusedDate = normalized;
    _loadEntry();
    notifyListeners();
  }

  void reload() {
    debugPrint('[HomeViewModel] reload for $_selectedDate');
    _loadEntry();
    _recomputeEntriesByDay();
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

  /// Creates a new entry for the currently selected date using [layout].
  /// Updates state and returns the newly created entry so the caller can
  /// navigate into the editor.
  JournalEntry createEntryWithLayout(JournalLayout layout) {
    final entry = _repository.createEntryForDate(_selectedDate, layout: layout);
    _currentEntry = entry;
    debugPrint('[HomeViewModel] createEntryWithLayout -> $entry');
    // No explicit recompute needed — repo notification will fire and call
    // _onRepositoryChanged. notify here so the screen sees the new entry
    // immediately without waiting for the async notification.
    notifyListeners();
    return entry;
  }

  void _loadEntry() {
    final entry = _repository.getEntryForDate(_selectedDate);
    debugPrint('[HomeViewModel] loaded $entry');
    _currentEntry = entry;
  }

  void _recomputeEntriesByDay() {
    _entriesByDay = _repository
        .getAllEntries()
        .map((e) => _dateOnly(e.date))
        .toSet();
  }

  void _onRepositoryChanged() {
    // Repository surface-area changes (create/delete/save/sweep) — re-read
    // the entry for the currently-selected date in case it was mutated or
    // removed elsewhere (e.g. an empty-past-entry sweep on app resume),
    // and recompute the dot-indicator set.
    debugPrint('[HomeViewModel] repository changed; refreshing');
    _loadEntry();
    _recomputeEntriesByDay();
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
