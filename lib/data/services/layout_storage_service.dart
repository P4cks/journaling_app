import 'package:hive_ce/hive.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';

class LayoutStorageService {
  final Box<JournalLayout> _box;

  LayoutStorageService(this._box);

  JournalLayout? getLayout(String id) => _box.get(id);

  List<JournalLayout> getAllLayouts() => _box.values.toList();

  Future<void> saveLayout(JournalLayout layout) =>
      _box.put(layout.id, layout);

  Future<void> deleteLayout(String id) => _box.delete(id);

  bool get isEmpty => _box.isEmpty;
}
