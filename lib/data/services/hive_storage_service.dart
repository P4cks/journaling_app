import 'package:hive_ce/hive.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

class HiveStorageService {
  final Box<JournalEntry> _box;

  HiveStorageService(this._box);

  JournalEntry? getJournalEntry(String key) => _box.get(key);

  Future<void> saveJournalEntry(String key, JournalEntry entry) =>
      _box.put(key, entry);

  Future<void> deleteJournalEntry(String key) => _box.delete(key);

  List<JournalEntry> getAllJournalEntries() => _box.values.toList();
}
