import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';

/// View model for the merged main journal screen.
///
/// Owns the selected date, the sorted list of entries (data source for
/// the swipe pager), the dot-set for the calendar, and the per-entry
/// mutations (block / title / layout). Fuses the responsibilities of
/// the former `HomeViewModel` and `JournalEntryEditorViewModel`.
class MainJournalViewModel extends ChangeNotifier {
  MainJournalViewModel({
    required JournalRepository journalRepository,
    required LayoutRepository layoutRepository,
    DateTime? initialDate,
  }) : _repository = journalRepository,
       _layoutRepository = layoutRepository,
       _selectedDate = _dateOnly(initialDate ?? DateTime.now()) {
    debugPrint('[MainJournalVM] init selectedDate=$_selectedDate');
    _repository.addListener(_onRepositoryChanged);
    _rebuildEntries();
  }

  final JournalRepository _repository;
  final LayoutRepository _layoutRepository;

  DateTime _selectedDate;
  List<JournalEntry> _entries = const [];
  Set<DateTime> _entriesByDay = const <DateTime>{};

  DateTime get selectedDate => _selectedDate;

  /// All entries the user has, sorted ascending by date — drives the
  /// horizontal `PageView` on the screen.
  List<JournalEntry> get entries => _entries;

  /// Set of normalized days that have an entry — drives the calendar's
  /// dot marker.
  Set<DateTime> get entriesByDay => _entriesByDay;

  /// Entry for [date], or `null` when none exists. Cheap O(1) via the
  /// repository — used by the screen to decide between PageView vs
  /// empty-day rendering.
  JournalEntry? entryForDate(DateTime date) =>
      _repository.getEntryForDate(_dateOnly(date));

  JournalEntry? get currentEntry => entryForDate(_selectedDate);

  /// Page index of the entry for [date] in [entries], or `null` when
  /// the date has no entry.
  int? pageIndexForDate(DateTime date) {
    final key = _dateOnly(date);
    for (var i = 0; i < _entries.length; i++) {
      if (_dateOnly(_entries[i].date) == key) return i;
    }
    return null;
  }

  void setSelectedDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_selectedDate == normalized) return;
    debugPrint('[MainJournalVM] setSelectedDate $_selectedDate -> $normalized');
    _selectedDate = normalized;
    notifyListeners();
  }

  List<JournalLayout> getAvailableLayouts() => _layoutRepository.getAll();

  /// Materializes an entry for the currently-selected date using
  /// [layout]. Used by the Make-entry CTA.
  JournalEntry createWithLayout(JournalLayout layout) {
    final entry = _repository.createEntryForDate(_selectedDate, layout: layout);
    debugPrint('[MainJournalVM] createWithLayout -> $entry');
    // The repository notify will fire and rebuild our entries list; the
    // notifyListeners below ensures the screen sees the new entry
    // without waiting for the async tick.
    notifyListeners();
    return entry;
  }

  void updateBlock(JournalBlockData updated) {
    final current = entryForDate(_selectedDate);
    if (current == null) {
      debugPrint('[MainJournalVM] updateBlock ignored — no entry');
      return;
    }
    final newBlocks = [
      for (final b in current.widgets)
        if (b.id == updated.id) updated else b,
    ];
    final next = current.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    _repository.saveJournalEntry(next);
    debugPrint('[MainJournalVM] updateBlock id=${updated.id}');
  }

  /// Updates the entry's title. Empty/whitespace → clears (date
  /// fallback). The repository's notification will rebuild our state.
  void updateTitle(String? newTitle) {
    final current = entryForDate(_selectedDate);
    if (current == null) {
      debugPrint('[MainJournalVM] updateTitle ignored — no entry');
      return;
    }
    final trimmed = newTitle?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (current.title == normalized) return;
    final next = current.copyWith(
      title: normalized,
      clearTitle: normalized == null,
      lastModified: DateTime.now(),
    );
    _repository.saveJournalEntry(next);
    debugPrint('[MainJournalVM] updateTitle -> "${normalized ?? '<null>'}"');
  }

  /// Destructive — replaces the current entry's blocks with the
  /// materialized layout. Caller should confirm before invoking.
  void applyLayout(JournalLayout layout) {
    final current = entryForDate(_selectedDate);
    if (current == null) {
      debugPrint('[MainJournalVM] applyLayout ignored — no entry');
      return;
    }
    final newBlocks = _repository.materializeLayout(layout, _selectedDate);
    final next = current.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    _repository.saveJournalEntry(next);
    debugPrint('[MainJournalVM] applyLayout "${layout.name}" (${layout.id})');
  }

  void _rebuildEntries() {
    final all = [..._repository.getAllEntries()]
      ..sort((a, b) => _dateOnly(a.date).compareTo(_dateOnly(b.date)));
    _entries = List.unmodifiable(all);
    _entriesByDay = {for (final e in all) _dateOnly(e.date)};
  }

  void _onRepositoryChanged() {
    debugPrint('[MainJournalVM] repository changed; refreshing');
    _rebuildEntries();
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
