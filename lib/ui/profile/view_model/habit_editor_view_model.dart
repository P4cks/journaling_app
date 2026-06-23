import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/habit_definition.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Backs `HabitEditorScreen`. Mirrors `CustomBlockEditorViewModel`'s
/// draft / `isDirty` / save-on-leave shape, but a habit definition is
/// simpler — just a title + a single icon (no item list):
/// snapshot on construction, mutate freely as drafts, only write back
/// via [save] when the user explicitly chooses Save on leave.
///
/// `definitionId == null` → creating a brand-new definition (fresh
/// uuid, blank title, no icon). Otherwise we hydrate from the registry.
///
/// Validation:
/// - Title trimmed; non-empty; unique (case-insensitive against every
///   other habit in the registry).
/// The icon is optional — habits resolve a question-mark fallback when
/// `iconName` is empty/unknown, so it never blocks save.
class HabitEditorViewModel extends ChangeNotifier {
  HabitEditorViewModel({required BlockSettings settings, String? definitionId})
    : _settings = settings {
    final existing = definitionId == null
        ? null
        : settings.findHabit(definitionId);
    if (existing != null) {
      _id = existing.id;
      titleController = TextEditingController(text: existing.title);
      _iconName = existing.iconName.isEmpty ? null : existing.iconName;
      _isNew = false;
    } else {
      _id = _uuid.v4();
      titleController = TextEditingController();
      _iconName = null;
      _isNew = true;
    }
    _snapshotInitial();
    titleController.addListener(_notify);
  }

  final BlockSettings _settings;
  late final String _id;
  late final bool _isNew;
  late final TextEditingController titleController;
  String? _iconName;

  late String _initialTitle;
  late String? _initialIconName;

  void _snapshotInitial() {
    _initialTitle = titleController.text.trim();
    _initialIconName = _iconName;
  }

  void _notify() => notifyListeners();

  String get id => _id;
  bool get isNew => _isNew;
  String? get iconName => _iconName;

  void setIconName(String? name) {
    if (_iconName == name) return;
    _iconName = name;
    notifyListeners();
  }

  bool get isDirty {
    if (titleController.text.trim() != _initialTitle) return true;
    if (_iconName != _initialIconName) return true;
    return false;
  }

  /// Non-null when the title is empty or clashes (case-insensitive)
  /// with another habit's title in the registry. Always blocks save
  /// when empty — habits must have a title so they're addressable in
  /// the Add-Block sheet and Block Settings sections.
  String? get titleError {
    final raw = titleController.text.trim();
    if (raw.isEmpty) return 'Add a title';
    final candidate = raw.toLowerCase();
    for (final def in _settings.habits) {
      if (def.id == _id) continue;
      if (def.title.trim().toLowerCase() == candidate) {
        return 'A habit with this title already exists';
      }
    }
    return null;
  }

  bool get canSave => titleError == null;

  /// Writes the definition back to the registry and re-snapshots so
  /// `isDirty` reads false post-save. Returns false (without writing)
  /// when validation fails.
  Future<bool> save() async {
    if (!canSave) return false;
    final definition = HabitDefinition(
      id: _id,
      title: titleController.text.trim(),
      iconName: _iconName ?? '',
    );
    if (_isNew) {
      await _settings.addHabit(definition);
    } else {
      await _settings.updateHabit(definition);
    }
    _snapshotInitial();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    titleController.removeListener(_notify);
    titleController.dispose();
    super.dispose();
  }
}
