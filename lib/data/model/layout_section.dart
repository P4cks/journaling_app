import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';

/// One ordered section of a [JournalLayout].
///
/// Shape depends on [kind]:
/// - [SectionKind.text] — `rows` is `null`, `blocks` is empty. The
///   materialised entry section will carry a single fresh
///   `JournalBlockData(type: textBlock)` for the user's text.
/// - [SectionKind.blockGrid] — `rows` is 1..4 (2 cols fixed), `blocks`
///   has exactly `2 * rows` templates whose `type` determines what each
///   tile renders. Templates are materialised one-for-one when an entry
///   is created.
/// - [SectionKind.featureBlock] — `rows` is `null`, `blocks` has
///   exactly one template (a `photoBlock` or `memoryBlock`)
///   materialised one-for-one into a 2×2 entry block.
///
/// `BlockTemplate.configJson` is currently always `'{}'` — see
/// [block_template.dart] for the forward-compat reasoning.
class LayoutSection {
  final String id;
  final SectionKind kind;
  final int? rows;
  final List<BlockTemplate> blocks;

  /// For [SectionKind.wannado] only: the id of the `WannadoDefinition`
  /// (in the `BlockSettings` registry) this section renders. `null` for
  /// every other kind, and for legacy wannado sections saved before the
  /// definition-backed model (they render an empty placeholder).
  ///
  /// Appended last — `hive_ce` reads missing fields as `null`, so this is
  /// a backward-compatible add with no box-name bump (see hive/CLAUDE.md).
  final String? definitionId;

  const LayoutSection({
    required this.id,
    required this.kind,
    required this.blocks,
    this.rows,
    this.definitionId,
  });

  LayoutSection copyWith({
    String? id,
    SectionKind? kind,
    int? rows,
    List<BlockTemplate>? blocks,
    String? definitionId,
    bool clearRows = false,
    bool clearDefinitionId = false,
  }) => LayoutSection(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    rows: clearRows ? null : (rows ?? this.rows),
    blocks: blocks ?? this.blocks,
    definitionId: clearDefinitionId
        ? null
        : (definitionId ?? this.definitionId),
  );

  @override
  String toString() =>
      'LayoutSection(id: $id, kind: $kind, rows: $rows, blocks: ${blocks.length}, definitionId: $definitionId)';
}
