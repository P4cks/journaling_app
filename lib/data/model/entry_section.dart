import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';

/// One ordered section of a [JournalEntry]'s materialised content.
///
/// Mirrors `LayoutSection` but holds **materialised** blocks rather
/// than templates:
/// - [SectionKind.text] — `blocks` contains exactly one
///   `JournalBlockData` of type `BlockType.textBlock`; the user's text
///   lives in that block's `TextBlockContent`. `rows` is `null`.
/// - [SectionKind.blockGrid] — `rows` is 1..4, `blocks` has `2 * rows`
///   materialised entries, one per layout template.
/// - [SectionKind.featureBlock] — `rows` is `null`, `blocks` has
///   exactly one materialised entry (a `photoBlock` or `memoryBlock`)
///   rendered at 2×2 (full body width, square).
class EntrySection {
  final String id;
  final SectionKind kind;
  final int? rows;
  final List<JournalBlockData> blocks;

  /// For [SectionKind.wannado] only: the id of the `WannadoDefinition`
  /// this section renders (carried over from the source `LayoutSection`).
  /// `null` for every other kind, and for legacy wannado sections saved
  /// before the definition-backed model.
  ///
  /// Appended last — `hive_ce` reads missing fields as `null`, so this is
  /// a backward-compatible add with no box-name bump (see hive/CLAUDE.md).
  final String? definitionId;

  const EntrySection({
    required this.id,
    required this.kind,
    required this.blocks,
    this.rows,
    this.definitionId,
  });

  EntrySection copyWith({
    String? id,
    SectionKind? kind,
    int? rows,
    List<JournalBlockData>? blocks,
    String? definitionId,
    bool clearRows = false,
    bool clearDefinitionId = false,
  }) => EntrySection(
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
      'EntrySection(id: $id, kind: $kind, rows: $rows, blocks: ${blocks.length}, definitionId: $definitionId)';
}
