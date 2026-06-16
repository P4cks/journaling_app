import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/wannado_definition.dart';
import 'package:journaling_app_rewrite/data/model/wannado_item.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Backs `WannadoEditorScreen`. Mirrors `CustomBlockEditorViewModel`'s
/// draft / `isDirty` / save-on-leave shape: snapshot on construction,
/// mutate freely as drafts, only write back via [save] when the user
/// explicitly chooses Save on leave.
///
/// `definitionId == null` → creating a brand-new wanna-do carousel
/// definition (fresh uuid, blank fields). Otherwise we hydrate from the
/// registry.
///
/// Validation:
/// - Title trimmed; non-empty; unique (case-insensitive against every
///   other definition in the registry).
/// - At least 1 item in `items` (a carousel with nothing to rotate is
///   pointless).
/// Both surface through [titleError] / [itemsError] and gate [canSave].
class WannadoEditorViewModel extends ChangeNotifier {
  WannadoEditorViewModel({
    required BlockSettings settings,
    String? definitionId,
  }) : _settings = settings {
    final existing = definitionId == null
        ? null
        : settings.findWannadoDefinition(definitionId);
    if (existing != null) {
      _id = existing.id;
      titleController = TextEditingController(text: existing.title);
      _items = List<WannadoItem>.from(existing.items);
      _isNew = false;
    } else {
      _id = _uuid.v4();
      titleController = TextEditingController();
      _items = [];
      _isNew = true;
    }
    _snapshotInitial();
    titleController.addListener(_notify);
  }

  final BlockSettings _settings;
  late final String _id;
  late final bool _isNew;
  late final TextEditingController titleController;
  late List<WannadoItem> _items;

  late String _initialTitle;
  late List<WannadoItem> _initialItems;

  void _snapshotInitial() {
    _initialTitle = titleController.text.trim();
    _initialItems = List<WannadoItem>.from(_items);
  }

  void _notify() => notifyListeners();

  String get id => _id;
  bool get isNew => _isNew;
  List<WannadoItem> get items => List.unmodifiable(_items);

  bool get isDirty {
    if (titleController.text.trim() != _initialTitle) return true;
    if (_items.length != _initialItems.length) return true;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id != _initialItems[i].id ||
          _items[i].text != _initialItems[i].text) {
        return true;
      }
    }
    return false;
  }

  /// Non-null when the title is empty or clashes (case-insensitive)
  /// with another definition's title in the registry. Always blocks
  /// save when empty — definitions must have a title so they're
  /// addressable in the Add-Section picker and Block Settings.
  String? get titleError {
    final raw = titleController.text.trim();
    if (raw.isEmpty) return 'Add a title';
    final candidate = raw.toLowerCase();
    for (final def in _settings.wannadoDefinitions) {
      if (def.id == _id) continue;
      if (def.title.trim().toLowerCase() == candidate) {
        return 'A wanna-do carousel with this title already exists';
      }
    }
    return null;
  }

  /// Non-null when there are no items. Surfaced inline near the items
  /// list and gates [canSave].
  String? get itemsError {
    if (_items.isEmpty) return 'Add at least one item';
    return null;
  }

  bool get canSave => titleError == null && itemsError == null;

  void addItem(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _items = [..._items, WannadoItem(id: _uuid.v4(), text: trimmed)];
    notifyListeners();
  }

  void updateItemAt(int index, String text) {
    if (index < 0 || index >= _items.length) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final next = [..._items];
    next[index] = next[index].copyWith(text: trimmed);
    _items = next;
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final next = [..._items]..removeAt(index);
    _items = next;
    notifyListeners();
  }

  /// Wired to `ReorderableListView.onReorderItem`, which already
  /// adjusts `newIndex` for the removed source item — so this is a
  /// plain `removeAt + insert` with no further translation.
  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex == oldIndex) return;
    final list = [..._items];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _items = list;
    notifyListeners();
  }

  /// Writes the definition back to the registry and re-snapshots so
  /// `isDirty` reads false post-save. Returns false (without writing)
  /// when validation fails.
  Future<bool> save() async {
    if (!canSave) return false;
    final definition = WannadoDefinition(
      id: _id,
      title: titleController.text.trim(),
      items: List<WannadoItem>.from(_items),
    );
    if (_isNew) {
      await _settings.addWannado(definition);
    } else {
      await _settings.updateWannado(definition);
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
