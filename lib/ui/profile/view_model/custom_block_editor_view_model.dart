import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Backs `CustomBlockEditorScreen`. Mirrors `LayoutEditorViewModel`'s
/// draft / `isDirty` / save-on-leave shape:
/// snapshot on construction, mutate freely as drafts, only write
/// back via [save] when the user explicitly chooses Save on leave.
///
/// `definitionId == null` → creating a brand-new definition (fresh
/// uuid, blank fields). Otherwise we hydrate from the registry.
///
/// Validation:
/// - Title trimmed; non-empty; unique (case-insensitive against every
///   other definition in the registry).
/// - At least 2 items in `items`.
/// Both surface through [titleError] / [itemsError] and gate [canSave].
class CustomBlockEditorViewModel extends ChangeNotifier {
  CustomBlockEditorViewModel({
    required BlockSettings settings,
    String? definitionId,
  }) : _settings = settings {
    final existing = definitionId == null
        ? null
        : settings.findCustomCarousel(definitionId);
    if (existing != null) {
      _id = existing.id;
      titleController = TextEditingController(text: existing.title);
      _items = List<CarouselItem>.from(existing.items);
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
  late List<CarouselItem> _items;

  late String _initialTitle;
  late List<CarouselItem> _initialItems;

  void _snapshotInitial() {
    _initialTitle = titleController.text.trim();
    _initialItems = List<CarouselItem>.from(_items);
  }

  void _notify() => notifyListeners();

  String get id => _id;
  bool get isNew => _isNew;
  List<CarouselItem> get items => List.unmodifiable(_items);

  bool get isDirty {
    if (titleController.text.trim() != _initialTitle) return true;
    if (_items.length != _initialItems.length) return true;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i] != _initialItems[i]) return true;
    }
    return false;
  }

  /// Non-null when the title is empty or clashes (case-insensitive)
  /// with another definition's title in the registry. Always blocks
  /// save when empty — custom blocks must have a title so they're
  /// addressable in the Add-Block sheet and Block Settings sections.
  String? get titleError {
    final raw = titleController.text.trim();
    if (raw.isEmpty) return 'Add a title';
    final candidate = raw.toLowerCase();
    for (final def in _settings.customCarousels) {
      if (def.id == _id) continue;
      if (def.title.trim().toLowerCase() == candidate) {
        return 'A custom block with this title already exists';
      }
    }
    return null;
  }

  /// Non-null when items doesn't meet the minimum size (2). Surfaced
  /// inline near the items list and gates [canSave].
  String? get itemsError {
    if (_items.length < 2) {
      return 'Add at least two items';
    }
    return null;
  }

  bool get canSave => titleError == null && itemsError == null;

  void addItem(CarouselItem item) {
    _items = [..._items, item];
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
    final definition = CustomCarouselDefinition(
      id: _id,
      title: titleController.text.trim(),
      items: List<CarouselItem>.from(_items),
    );
    if (_isNew) {
      await _settings.addCustomCarousel(definition);
    } else {
      await _settings.updateCustomCarousel(definition);
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
