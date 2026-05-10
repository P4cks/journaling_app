import 'package:hive_ce/hive.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_collection.dart';

class HiveStorageService {
  final Box<JournalEntryCollection> _box;
  HiveStorageService(this._box);

  JournalEntryCollection? getJournalEntryCollection(String key){
    return _box.get(key);
  }

  Future<void> saveJournalEntryCollection(String key, JournalEntryCollection entry) {
    return _box.put(key, entry);
  }

  Future<void> deleteJournalEntryCollection(String key){
    return _box.delete(key);
  }

  List<JournalEntryCollection> getAllJournalEntryCollections() => _box.values.toList();
}