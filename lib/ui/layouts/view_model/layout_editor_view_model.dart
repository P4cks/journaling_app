import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/layout_section.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
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

/// Editor-side mutable representation of a [LayoutSection].
class SectionDraft {
  SectionDraft({
    required this.id,
    required this.kind,
    required this.slots,
    this.rows,
  });

  final String id;
  final SectionKind kind;
  int? rows;
  List<BlockSlot> slots;
}

class LayoutEditorViewModel extends ChangeNotifier {
  LayoutEditorViewModel({
    required LayoutRepository repository,
    String? layoutId,
    LayoutKind? initialKind,
  }) : _repository = repository {
    final existing = layoutId == null ? null : _repository.getById(layoutId);
    if (existing != null) {
      _id = existing.id;
      _kind = existing.kind;
      _sections = [
        for (final s in existing.sections)
          SectionDraft(
            id: s.id,
            kind: s.kind,
            rows: s.rows,
            slots: [
              for (final template in s.blocks)
                BlockSlot(id: template.id, type: template.type),
            ],
          ),
      ];
      nameController = TextEditingController(text: existing.name);
      _iconName = existing.iconName;
      _isNew = false;
    } else {
      _id = _uuid.v4();
      _kind = initialKind ?? LayoutKind.blockOnly;
      _sections = _seedSectionsFor(_kind);
      nameController = TextEditingController();
      _iconName = null;
      _isNew = true;
    }
    _snapshotInitial();
    nameController.addListener(_onNameChanged);
    debugPrint(
      '[LayoutEditorVM] init id=$_id isNew=$_isNew kind=$_kind '
      'name="${nameController.text}" icon=$_iconName '
      'sections=${_sections.length}',
    );
  }

  final LayoutRepository _repository;
  late final String _id;
  late final LayoutKind _kind;
  late final TextEditingController nameController;
  late List<SectionDraft> _sections;
  late final bool _isNew;
  String? _iconName;

  late String _initialName;
  late String? _initialIconName;
  late List<_SectionSnapshot> _initialSections;

  void _snapshotInitial() {
    _initialName = nameController.text.trim();
    _initialIconName = _iconName;
    _initialSections = [
      for (final s in _sections)
        _SectionSnapshot(
          kind: s.kind,
          rows: s.rows,
          slotTypes: [for (final slot in s.slots) slot.type],
        ),
    ];
  }

  String get id => _id;
  LayoutKind get kind => _kind;
  bool get isNew => _isNew;
  List<SectionDraft> get sections => List.unmodifiable(_sections);
  String? get iconName => _iconName;
  bool get canSave => nameController.text.trim().isNotEmpty && !nameConflict;

  /// True when the trimmed, case-insensitive name matches another
  /// layout in the repository (excluding this one's own id). Used by
  /// the editor screen to block save with a SnackBar instead of
  /// silently overwriting or producing two layouts with the same name.
  bool get nameConflict {
    final candidate = nameController.text.trim().toLowerCase();
    if (candidate.isEmpty) return false;
    for (final layout in _repository.getAll()) {
      if (layout.id == _id) continue;
      if (layout.name.trim().toLowerCase() == candidate) return true;
    }
    return false;
  }

  bool get isDirty {
    if (nameController.text.trim() != _initialName) return true;
    if (_iconName != _initialIconName) return true;
    if (_sections.length != _initialSections.length) return true;
    for (var i = 0; i < _sections.length; i++) {
      final cur = _sections[i];
      final snap = _initialSections[i];
      if (cur.kind != snap.kind) return true;
      if (cur.rows != snap.rows) return true;
      if (cur.slots.length != snap.slotTypes.length) return true;
      for (var j = 0; j < cur.slots.length; j++) {
        if (cur.slots[j].type != snap.slotTypes[j]) return true;
      }
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

  // ---------------------------------------------------------------------------
  // blockOnly — operate on the single implicit section.
  // ---------------------------------------------------------------------------

  SectionDraft get _blockOnlySection {
    assert(_kind == LayoutKind.blockOnly);
    return _sections.first;
  }

  void addBlock(BlockType type) {
    final s = _blockOnlySection;
    s.slots = [...s.slots, BlockSlot(id: _uuid.v4(), type: type)];
    debugPrint(
      '[LayoutEditorVM] addBlock $type (total=${s.slots.length})',
    );
    notifyListeners();
  }

  void removeSlot(String slotId) {
    final s = _blockOnlySection;
    final next = [...s.slots]..removeWhere((slot) => slot.id == slotId);
    if (next.length == s.slots.length) return;
    s.slots = next;
    debugPrint(
      '[LayoutEditorVM] removeSlot $slotId (total=${s.slots.length})',
    );
    notifyListeners();
  }

  void moveSlot(int from, int to) {
    final s = _blockOnlySection;
    if (from < 0 || from >= s.slots.length) return;
    if (to == from || to == from + 1) return;
    final adjusted = to > from ? to - 1 : to;
    final list = [...s.slots];
    final item = list.removeAt(from);
    list.insert(adjusted, item);
    s.slots = list;
    debugPrint('[LayoutEditorVM] moveSlot $from -> $to (adjusted=$adjusted)');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // fixedFourPlusText — 0..4 filled slots in the first section; the editor
  // pads the visual 2x2 grid with "+ Add block" placeholders.
  // ---------------------------------------------------------------------------

  static const int fixedFourCapacity = 4;

  void addBlockInFixedFour(BlockType type) {
    assert(_kind == LayoutKind.fixedFourPlusText);
    final section = _sections.first;
    if (section.slots.length >= fixedFourCapacity) return;
    section.slots = [...section.slots, BlockSlot(id: _uuid.v4(), type: type)];
    debugPrint(
      '[LayoutEditorVM] addBlockInFixedFour $type (slots=${section.slots.length})',
    );
    notifyListeners();
  }

  void removeFixedFourSlot(String slotId) {
    assert(_kind == LayoutKind.fixedFourPlusText);
    final section = _sections.first;
    final next = [...section.slots]..removeWhere((s) => s.id == slotId);
    if (next.length == section.slots.length) return;
    section.slots = next;
    debugPrint(
      '[LayoutEditorVM] removeFixedFourSlot $slotId (slots=${section.slots.length})',
    );
    notifyListeners();
  }

  void replaceSlotType(String slotId, BlockType newType) {
    for (final section in _sections) {
      for (var i = 0; i < section.slots.length; i++) {
        if (section.slots[i].id == slotId) {
          if (section.slots[i].type == newType) return;
          final updated = [...section.slots];
          updated[i] = updated[i].copyWith(type: newType);
          section.slots = updated;
          debugPrint(
            '[LayoutEditorVM] replaceSlotType $slotId -> $newType',
          );
          notifyListeners();
          return;
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // custom — full section toolkit.
  // ---------------------------------------------------------------------------

  void addSection(SectionKind kind) {
    _sections = [
      ..._sections,
      SectionDraft(
        id: _uuid.v4(),
        kind: kind,
        rows: kind == SectionKind.blockGrid ? 0 : null,
        slots: const [],
      ),
    ];
    debugPrint('[LayoutEditorVM] addSection $kind');
    notifyListeners();
  }

  void removeSection(String sectionId) {
    final next = [..._sections]..removeWhere((s) => s.id == sectionId);
    if (next.length == _sections.length) return;
    _sections = next;
    debugPrint('[LayoutEditorVM] removeSection $sectionId');
    notifyListeners();
  }

  void moveSection(int from, int to) {
    if (from < 0 || from >= _sections.length) return;
    if (to < 0 || to >= _sections.length) return;
    if (from == to) return;
    final list = [..._sections];
    final item = list.removeAt(from);
    list.insert(to, item);
    _sections = list;
    debugPrint('[LayoutEditorVM] moveSection $from -> $to');
    notifyListeners();
  }

  void addBlockInSection(String sectionId, BlockType type) {
    final section = _sections.firstWhere((s) => s.id == sectionId);
    if (section.kind != SectionKind.blockGrid) return;
    section.slots = [...section.slots, BlockSlot(id: _uuid.v4(), type: type)];
    // `rows` is purely a renderer hint derived from the slot count;
    // the BlockGrid sizes itself to its blocks regardless.
    section.rows = (section.slots.length / 2).ceil();
    debugPrint(
      '[LayoutEditorVM] addBlockInSection $sectionId $type '
      '(slots=${section.slots.length}, rows=${section.rows})',
    );
    notifyListeners();
  }

  void removeSlotInSection(String sectionId, String slotId) {
    final section = _sections.firstWhere((s) => s.id == sectionId);
    final next = [...section.slots]..removeWhere((s) => s.id == slotId);
    if (next.length == section.slots.length) return;
    section.slots = next;
    section.rows = (section.slots.length / 2).ceil();
    debugPrint('[LayoutEditorVM] removeSlotInSection $sectionId $slotId');
    notifyListeners();
  }

  void moveSlotInSection(String sectionId, int from, int to) {
    final section = _sections.firstWhere((s) => s.id == sectionId);
    if (from < 0 || from >= section.slots.length) return;
    if (to == from || to == from + 1) return;
    final adjusted = to > from ? to - 1 : to;
    final list = [...section.slots];
    final item = list.removeAt(from);
    list.insert(adjusted, item);
    section.slots = list;
    debugPrint(
      '[LayoutEditorVM] moveSlotInSection $sectionId $from -> $to',
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<JournalLayout?> save() async {
    if (nameController.text.trim().isEmpty) {
      debugPrint('[LayoutEditorVM] save skipped (name empty)');
      return null;
    }
    if (nameConflict) {
      debugPrint(
        '[LayoutEditorVM] save skipped (name "${nameController.text.trim()}" '
        'conflicts with an existing layout)',
      );
      return null;
    }
    final layout = JournalLayout(
      id: _id,
      name: nameController.text.trim(),
      kind: _kind,
      sections: [
        for (final s in _sections)
          LayoutSection(
            id: s.id,
            kind: s.kind,
            rows: s.rows,
            blocks: [
              for (final slot in s.slots)
                BlockTemplate.create(id: slot.id, type: slot.type),
            ],
          ),
      ],
      iconName: _iconName,
    );
    await _repository.save(layout);
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

  // ---------------------------------------------------------------------------
  // Per-kind seeding for fresh layouts
  // ---------------------------------------------------------------------------

  static List<SectionDraft> _seedSectionsFor(LayoutKind kind) {
    switch (kind) {
      case LayoutKind.blockOnly:
        return [
          SectionDraft(
            id: _uuid.v4(),
            kind: SectionKind.blockGrid,
            rows: 0,
            slots: const [],
          ),
        ];
      case LayoutKind.fixedFourPlusText:
        return [
          SectionDraft(
            id: _uuid.v4(),
            kind: SectionKind.blockGrid,
            rows: 2, // renderer hint only; the editor always shows a 2x2 frame
            slots: const [],
          ),
          SectionDraft(
            id: _uuid.v4(),
            kind: SectionKind.text,
            slots: const [],
          ),
        ];
      case LayoutKind.custom:
        return [];
    }
  }
}

class _SectionSnapshot {
  const _SectionSnapshot({
    required this.kind,
    required this.rows,
    required this.slotTypes,
  });
  final SectionKind kind;
  final int? rows;
  final List<BlockType> slotTypes;
}
