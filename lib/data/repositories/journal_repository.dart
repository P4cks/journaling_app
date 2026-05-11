import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class JournalRepository {
  final HiveStorageService _storage;
  final LayoutRepository _layouts;

  JournalRepository(this._storage, this._layouts);

  String _dateKey(DateTime date) => date.toIso8601String();

  JournalEntry? getEntryForDate(DateTime date) {
    final key = _dateKey(date);
    final entry = _storage.getJournalEntry(key);
    debugPrint(
      '[JournalRepository] getEntryForDate($key) -> ${entry ?? 'null'}',
    );
    return entry;
  }

  JournalEntry getOrCreateEntryForDate(DateTime date) {
    final existing = getEntryForDate(date);
    if (existing != null) return existing;

    final layout = _layouts.getDefault();
    final entry = JournalEntry(
      id: _uuid.v4(),
      date: date,
      lastModified: DateTime.now(),
      widgets: _blocksFromLayout(layout),
    );
    debugPrint(
      '[JournalRepository] created $entry from layout=${layout?.name ?? '<none>'}',
    );
    saveJournalEntry(entry);
    return entry;
  }

  Future<void> saveJournalEntry(JournalEntry entry) {
    debugPrint('[JournalRepository] saveJournalEntry $entry');
    return _storage.saveJournalEntry(_dateKey(entry.date), entry);
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
