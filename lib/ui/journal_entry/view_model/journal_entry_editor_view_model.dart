import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';

class JournalEntryEditorViewModel extends ChangeNotifier {
  JournalEntryEditorViewModel({
    required JournalRepository repository,
    required LayoutRepository layoutRepository,
    required DateTime date,
  })  : _repository = repository,
        _layoutRepository = layoutRepository,
        _date = date,
        _entry = repository.getEntryForDate(date) {
    debugPrint('[EditorVM] init for date=$_date entry=$_entry');
  }

  final JournalRepository _repository;
  final LayoutRepository _layoutRepository;
  final DateTime _date;
  JournalEntry? _entry;

  DateTime get date => _date;
  JournalEntry? get entry => _entry;
  bool get hasEntry => _entry != null;

  List<JournalLayout> getAvailableLayouts() => _layoutRepository.getAll();

  /// Materializes an entry for this date using [layout]. Used by the
  /// editor's "Make entry" CTA when reached via deep link for a day that
  /// doesn't yet have one.
  void createWithLayout(JournalLayout layout) {
    final entry = _repository.createEntryForDate(_date, layout: layout);
    _entry = entry;
    debugPrint('[EditorVM] createWithLayout -> $entry');
    notifyListeners();
  }

  void updateBlock(JournalBlockData updated) {
    final current = _entry;
    if (current == null) {
      debugPrint('[EditorVM] updateBlock ignored — no entry');
      return;
    }
    final newBlocks = [
      for (final b in current.widgets)
        if (b.id == updated.id) updated else b,
    ];
    _entry = current.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    debugPrint('[EditorVM] updateBlock id=${updated.id} type=${updated.type}');
    _repository.saveJournalEntry(_entry!);
    notifyListeners();
  }

  /// Updates the entry's title. Pass `null` (or an empty/whitespace-only
  /// string, which is normalized to `null`) to clear the title — the UI
  /// will fall back to displaying the date.
  void updateTitle(String? newTitle) {
    final current = _entry;
    if (current == null) {
      debugPrint('[EditorVM] updateTitle ignored — no entry');
      return;
    }
    final trimmed = newTitle?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (current.title == normalized) return;
    _entry = current.copyWith(
      title: normalized,
      clearTitle: normalized == null,
      lastModified: DateTime.now(),
    );
    debugPrint('[EditorVM] updateTitle -> "${normalized ?? '<null>'}"');
    _repository.saveJournalEntry(_entry!);
    notifyListeners();
  }

  void applyLayout(JournalLayout layout) {
    final current = _entry;
    if (current == null) {
      debugPrint('[EditorVM] applyLayout ignored — no entry');
      return;
    }
    final newBlocks = _repository.materializeLayout(layout, _date);
    _entry = current.copyWith(
      widgets: newBlocks,
      lastModified: DateTime.now(),
    );
    debugPrint(
      '[EditorVM] applyLayout "${layout.name}" (${layout.id}) — ${newBlocks.length} blocks',
    );
    _repository.saveJournalEntry(_entry!);
    notifyListeners();
  }
}
