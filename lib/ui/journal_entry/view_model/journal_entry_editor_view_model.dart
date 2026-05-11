import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class JournalEntryEditorViewModel extends ChangeNotifier {
  JournalEntryEditorViewModel({
    required JournalRepository repository,
    required LayoutRepository layoutRepository,
    required DateTime date,
  })  : _repository = repository,
        _layoutRepository = layoutRepository,
        _date = date,
        _entry = repository.getOrCreateEntryForDate(date) {
    debugPrint('[EditorVM] init for date=$_date entry=$_entry');
  }

  final JournalRepository _repository;
  final LayoutRepository _layoutRepository;
  final DateTime _date;
  JournalEntry _entry;

  DateTime get date => _date;
  JournalEntry get entry => _entry;

  List<JournalLayout> getAvailableLayouts() => _layoutRepository.getAll();

  void updateBlock(JournalBlockData updated) {
    final newBlocks = [
      for (final b in _entry.widgets)
        if (b.id == updated.id) updated else b,
    ];
    _entry = _entry.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    debugPrint('[EditorVM] updateBlock id=${updated.id} type=${updated.type}');
    _repository.saveJournalEntry(_entry);
    notifyListeners();
  }

  void applyLayout(JournalLayout layout) {
    final newBlocks = [
      for (final type in layout.blocks)
        JournalBlockData.create(id: _uuid.v4(), type: type),
    ];
    _entry = _entry.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    debugPrint(
      '[EditorVM] applyLayout "${layout.name}" (${layout.id}) — ${newBlocks.length} blocks',
    );
    _repository.saveJournalEntry(_entry);
    notifyListeners();
  }
}
