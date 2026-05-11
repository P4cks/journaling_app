import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_emptiness.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class JournalRepository {
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

  /// Legacy lazy-create call. Kept temporarily for callers that still expect
  /// an entry to be auto-materialized on read. Will be removed once the
  /// home/editor flows switch to explicit creation via [createEntryForDate].
  @Deprecated('Use getEntryForDate + createEntryForDate explicitly. '
      'This method will be removed in the lifecycle-rework commit.')
  JournalEntry getOrCreateEntryForDate(DateTime date) {
    final existing = getEntryForDate(date);
    if (existing != null) return existing;
    return createEntryForDate(date);
  }

  Future<void> saveJournalEntry(JournalEntry entry) {
    debugPrint('[JournalRepository] saveJournalEntry $entry');
    return _storage.saveJournalEntry(_dateKey(entry.date), entry);
  }

  /// All entries across all days, in unspecified order. Sorting/grouping
  /// is the caller's responsibility.
  List<JournalEntry> getAllEntries() {
    final all = _storage.getAllJournalEntries();
    debugPrint('[JournalRepository] getAllEntries -> ${all.length} entries');
    return all;
  }

  Future<void> deleteEntry(JournalEntry entry) {
    debugPrint('[JournalRepository] deleteEntry $entry');
    return _storage.deleteJournalEntry(_dateKey(entry.date));
  }

  /// Removes past-day entries whose every block is at its default empty
  /// state. Today's entries are never deleted — the user may still be
  /// drafting. Pass [now] in tests; defaults to `DateTime.now()`.
  ///
  /// Returns the number of entries deleted.
  Future<int> sweepEmptyPastEntries({DateTime? now}) async {
    final today = _normalize(now ?? DateTime.now());
    var deleted = 0;
    for (final entry in getAllEntries()) {
      final entryDay = _normalize(entry.date);
      if (!entryDay.isBefore(today)) continue;
      if (!entry.hasNoContent) continue;
      await deleteEntry(entry);
      deleted++;
    }
    if (deleted > 0) {
      debugPrint(
        '[JournalRepository] sweepEmptyPastEntries removed $deleted entries',
      );
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
