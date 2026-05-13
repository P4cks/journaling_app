import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class BlockSlot {
  final String id;
  final BlockType type;

  const BlockSlot({required this.id, required this.type});

  BlockSlot copyWith({String? id, BlockType? type}) =>
      BlockSlot(id: id ?? this.id, type: type ?? this.type);
}

class LayoutEditorViewModel extends ChangeNotifier {
  LayoutEditorViewModel({
    required LayoutRepository repository,
    String? layoutId,
  }) : _repository = repository {
    final existing = layoutId == null ? null : _repository.getById(layoutId);
    if (existing != null) {
      _id = existing.id;
      _slots = [
        for (final template in existing.blocks)
          BlockSlot(id: template.id, type: template.type),
      ];
      nameController = TextEditingController(text: existing.name);
      _iconName = existing.iconName;
      _isNew = false;
    } else {
      _id = _uuid.v4();
      _slots = [];
      nameController = TextEditingController();
      _iconName = null;
      _isNew = true;
    }
    _snapshotInitial();
    nameController.addListener(_onNameChanged);
    debugPrint(
      '[LayoutEditorVM] init id=$_id isNew=$_isNew name="${nameController.text}" '
      'icon=$_iconName slots=${_slots.length}',
    );
  }

  final LayoutRepository _repository;
  late final String _id;
  late final TextEditingController nameController;
  late List<BlockSlot> _slots;
  late final bool _isNew;
  String? _iconName;

  late String _initialName;
  late String? _initialIconName;
  late List<BlockType> _initialSlotTypes;

  void _snapshotInitial() {
    _initialName = nameController.text.trim();
    _initialIconName = _iconName;
    _initialSlotTypes = [for (final s in _slots) s.type];
  }

  String get id => _id;
  bool get isNew => _isNew;
  List<BlockSlot> get slots => List.unmodifiable(_slots);
  String? get iconName => _iconName;
  bool get canSave => nameController.text.trim().isNotEmpty;

  bool get isDirty {
    if (nameController.text.trim() != _initialName) return true;
    if (_iconName != _initialIconName) return true;
    if (_slots.length != _initialSlotTypes.length) return true;
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].type != _initialSlotTypes[i]) return true;
    }
    return false;
  }

  void setIconName(String? name) {
    if (_iconName == name) return;
    _iconName = name;
    debugPrint('[LayoutEditorVM] setIconName -> $name');
    notifyListeners();
  }

  void _onNameChanged() {
    notifyListeners();
  }

  void addBlock(BlockType type) {
    _slots = [..._slots, BlockSlot(id: _uuid.v4(), type: type)];
    debugPrint('[LayoutEditorVM] addBlock $type (total=${_slots.length})');
    notifyListeners();
  }

  void removeSlot(String slotId) {
    final next = [..._slots]..removeWhere((s) => s.id == slotId);
    if (next.length == _slots.length) return;
    _slots = next;
    debugPrint('[LayoutEditorVM] removeSlot $slotId (total=${_slots.length})');
    notifyListeners();
  }

  void moveSlot(int from, int to) {
    if (from < 0 || from >= _slots.length) return;
    if (to == from || to == from + 1) {
      debugPrint('[LayoutEditorVM] moveSlot $from -> $to (no-op)');
      return;
    }
    final adjusted = to > from ? to - 1 : to;
    final list = [..._slots];
    final item = list.removeAt(from);
    list.insert(adjusted, item);
    _slots = list;
    debugPrint('[LayoutEditorVM] moveSlot $from -> $to (adjusted=$adjusted)');
    notifyListeners();
  }

  Future<JournalLayout?> save() async {
    if (!canSave) {
      debugPrint('[LayoutEditorVM] save skipped (name empty)');
      return null;
    }
    final layout = JournalLayout(
      id: _id,
      name: nameController.text.trim(),
      blocks: [
        for (final s in _slots) BlockTemplate.create(id: s.id, type: s.type),
      ],
      iconName: _iconName,
    );
    await _repository.save(layout);
    // Re-snapshot so isDirty reads false against the just-saved state.
    _snapshotInitial();
    debugPrint('[LayoutEditorVM] saved $layout');
    notifyListeners();
    return layout;
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    super.dispose();
  }
}
