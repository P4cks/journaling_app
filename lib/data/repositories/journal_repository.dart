import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_emptiness.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Single source of truth for journal entries. Extends [ChangeNotifier]
/// so view models can subscribe and react to creates/updates/deletes/sweeps
/// without each owner having to plumb refresh calls through.
class JournalRepository extends ChangeNotifier {
  final HiveStorageService _storage;
  final LayoutRepository _layouts;
  final BlockSettings _blockSettings;

  JournalRepository(this._storage, this._layouts, this._blockSettings);

  final Random _rng = Random();

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
    final normalizedDate = _normalize(date);
    final entry = JournalEntry(
      id: _uuid.v4(),
      date: normalizedDate,
      lastModified: DateTime.now(),
      widgets: materializeLayout(resolvedLayout, normalizedDate),
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

  /// Materializes [layout] into a fresh list of [JournalBlockData]s with
  /// per-type initial content seeded from block-type-global settings.
  ///
  /// Exposed publicly so the entry editor's `applyLayout` flow stays in
  /// sync with `createEntryForDate`. The [date] argument is used to
  /// pick prompts for `BlockType.promptBlock` slots (see
  /// [BlockSettings.pickPromptFor]).
  List<JournalBlockData> materializeLayout(
    JournalLayout? layout,
    DateTime date,
  ) {
    if (layout == null) return const [];
    var promptSlotIndex = 0;
    return [
      for (final template in layout.blocks)
        _materializeOne(template.type, date, () => promptSlotIndex++),
    ];
  }

  /// Picks a random non-empty block from a past (strictly-before [beforeDate])
  /// entry, restricted to types in [eligibleTypes]. Returns the parent
  /// entry's normalized date alongside the block so callers can persist
  /// both for tap-to-navigate. Returns `null` when no eligible blocks
  /// exist.
  ({DateTime date, JournalBlockData block})? pickRandomEligibleBlock({
    required DateTime beforeDate,
    required Set<BlockType> eligibleTypes,
  }) {
    final cutoff = _normalize(beforeDate);
    final pool = <({DateTime date, JournalBlockData block})>[];
    for (final entry in getAllEntries()) {
      if (!_normalize(entry.date).isBefore(cutoff)) continue;
      for (final block in entry.widgets) {
        if (!eligibleTypes.contains(block.type)) continue;
        if (block.isEmpty) continue;
        pool.add((date: _normalize(entry.date), block: block));
      }
    }
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  JournalBlockData _materializeOne(
    BlockType type,
    DateTime date,
    int Function() nextPromptSlotIndex,
  ) {
    switch (type) {
      case BlockType.promptBlock:
        final slot = nextPromptSlotIndex();
        final prompt = _blockSettings.pickPromptFor(
          date: date,
          slotIndex: slot,
        );
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: PromptBlockContent(
            prompt: prompt ?? '',
            answer: '',
          ).toMap(),
        );
      case BlockType.textBlock:
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.todoBlock:
      case BlockType.quoteBlock:
      case BlockType.memoryBlock:
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: const {},
        );
    }
  }
}
