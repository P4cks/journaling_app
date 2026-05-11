import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_emptiness.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Single source of truth for journal entries. Extends [ChangeNotifier]
/// so view models can subscribe and react to creates/updates/deletes/sweeps
/// without each owner having to plumb refresh calls through.
class JournalRepository extends ChangeNotifier {
  final HiveStorageService _storage;
  final LayoutRepository _layouts;

  JournalRepository(this._storage, this._layouts);

  /// Local-midnight normalization. All repository methods normalize inputs
  /// before keying so callers don't have to. Times-of-day on the input
  /// `DateTime` are discarded.
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateKey(DateTime date) => _normalize(date).toIso8601String();

  JournalEntry? getEntryForDate(DateTime date) {
    final key = _dateKey(date);
    final entry = _storage.getJournalEntry(key);
    debugPrint(
      '[JournalRepository] getEntryForDate($key) -> ${entry ?? 'null'}',
    );
    return entry;
  }

  /// Creates a new entry for [date] using either the explicitly supplied
  /// [layout] or, if `null`, the user's default layout. Saves and returns it.
  /// **Does not check for an existing entry** — callers should use
  /// [getEntryForDate] first if they want to avoid overwriting.
  JournalEntry createEntryForDate(
    DateTime date, {
    JournalLayout? layout,
  }) {
    final resolvedLayout = layout ?? _layouts.getDefault();
    final entry = JournalEntry(
      id: _uuid.v4(),
      date: _normalize(date),
      lastModified: DateTime.now(),
      widgets: _blocksFromLayout(resolvedLayout),
    );
    debugPrint(
      '[JournalRepository] created $entry from layout=${resolvedLayout?.name ?? '<none>'}',
    );
    saveJournalEntry(entry);
    return entry;
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    debugPrint('[JournalRepository] saveJournalEntry $entry');
    await _storage.saveJournalEntry(_dateKey(entry.date), entry);
    notifyListeners();
  }

  /// All entries across all days, in unspecified order. Sorting/grouping
  /// is the caller's responsibility.
  List<JournalEntry> getAllEntries() {
    final all = _storage.getAllJournalEntries();
    debugPrint('[JournalRepository] getAllEntries -> ${all.length} entries');
    return all;
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    debugPrint('[JournalRepository] deleteEntry $entry');
    await _storage.deleteJournalEntry(_dateKey(entry.date));
    notifyListeners();
  }

  /// Removes past-day entries whose every block is at its default empty
  /// state. Today's entries are never deleted — the user may still be
  /// drafting. Pass [now] in tests; defaults to `DateTime.now()`.
  ///
  /// Returns the number of entries deleted. Notifies once if any entry
  /// was deleted (not per-entry — listeners just need to know "something
  /// changed").
  Future<int> sweepEmptyPastEntries({DateTime? now}) async {
    final today = _normalize(now ?? DateTime.now());
    var deleted = 0;
    for (final entry in getAllEntries()) {
      final entryDay = _normalize(entry.date);
      if (!entryDay.isBefore(today)) continue;
      if (!entry.hasNoContent) continue;
      await _storage.deleteJournalEntry(_dateKey(entry.date));
      deleted++;
    }
    if (deleted > 0) {
      debugPrint(
        '[JournalRepository] sweepEmptyPastEntries removed $deleted entries',
      );
      notifyListeners();
    }
    return deleted;
  }

  List<JournalBlockData> _blocksFromLayout(JournalLayout? layout) {
    if (layout == null) return const [];
    return layout.blocks
        .map(
          (type) => JournalBlockData.create(
            id: _uuid.v4(),
            type: type,
            content: const {},
          ),
        )
        .toList();
  }
}
