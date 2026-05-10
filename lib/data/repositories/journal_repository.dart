import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_collection.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class JournalRepository {
  final HiveStorageService _storage;

  JournalRepository(this._storage);

  String _dateKey(DateTime date) {
    return date.toIso8601String();
  }

  JournalEntryCollection? getEntriesForDate(DateTime date) {
    return _storage.getJournalEntryCollection(_dateKey(date));
  }

  JournalEntryCollection getOrCreateJournalEntryCollection(DateTime date) {
    final existing = getEntriesForDate(date);
    if (existing != null) return existing;

    final entry = JournalEntryCollection(
      date: date,
      journalEntriesOnDate: [
        JournalEntry(id: _uuid.v4(), lastModified: DateTime.now(), widgets: []),
      ],
    );
    saveJournalEntryCollection(entry);
    return entry;
  }

  Future<void> saveJournalEntryCollection(JournalEntryCollection collection) {
    return _storage.saveJournalEntryCollection(
      _dateKey(collection.date),
      collection,
    );
  }

  Future<void> saveJournalEntryToCollection(DateTime date, JournalEntry entry) {
    JournalEntryCollection? collection = _storage.getJournalEntryCollection(
      _dateKey(date),
    );
    collection ??= JournalEntryCollection(
      date: date,
      journalEntriesOnDate: [entry],
    );
    return _storage.saveJournalEntryCollection(
      _dateKey(date),
      collection.copyWith(
        journalEntriesOnDate: [...collection.journalEntriesOnDate, entry],
      ),
    );
  }
}
