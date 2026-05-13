import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';

/// A contiguous group of entries within a single calendar month, used as
/// the section header on the entries list.
class MonthSection {
  const MonthSection({
    required this.year,
    required this.month,
    required this.entries,
  });

  final int year;
  final int month;
  final List<JournalEntry> entries;
}

class JournalEntriesViewModel extends ChangeNotifier {
  JournalEntriesViewModel({required JournalRepository repository})
    : _repository = repository {
    _repository.addListener(_onRepositoryChanged);
    _rebuild();
  }

  final JournalRepository _repository;

  List<MonthSection> _sections = const [];

  /// Month sections sorted newest-month-first; entries within each month
  /// sorted newest-first. Computed in the VM (not the widget) so the
  /// build path stays cheap on every rebuild.
  List<MonthSection> get sections => _sections;

  bool get isEmpty => _sections.isEmpty;

  void refresh() {
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    final all = _repository.getAllEntries()
      ..sort((a, b) => b.date.compareTo(a.date));

    final byKey = <int, List<JournalEntry>>{};
    final orderedKeys = <int>[];
    for (final entry in all) {
      final key = entry.date.year * 100 + entry.date.month;
      final bucket = byKey.putIfAbsent(key, () {
        orderedKeys.add(key);
        return <JournalEntry>[];
      });
      bucket.add(entry);
    }

    _sections = [
      for (final key in orderedKeys)
        MonthSection(year: key ~/ 100, month: key % 100, entries: byKey[key]!),
    ];
    debugPrint(
      '[EntriesVM] rebuilt: ${_sections.length} months, ${all.length} entries',
    );
  }

  void _onRepositoryChanged() {
    debugPrint('[EntriesVM] repository changed; rebuilding sections');
    _rebuild();
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
