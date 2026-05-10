import 'package:hive_ce/hive.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

class HiveStorageService {
  final Box<JournalEntry> _box;
  HiveStorageService(this._box);

  JournalEntry? getEntry(String key){
    return _box.get(key);
  }

  Future<void> saveEntry(String key, JournalEntry entry) {
    return _box.put(key, entry);
  }

  Future<void> deleteEntry(String key){
    return _box.delete(key);
  }

  List<JournalEntry> getAllEntries() => _box.values.toList();
}