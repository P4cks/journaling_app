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
class EntrySection {
  final String id;
  final SectionKind kind;
  final int? rows;
  final List<JournalBlockData> blocks;

  const EntrySection({
    required this.id,
    required this.kind,
    required this.blocks,
    this.rows,
  });

  EntrySection copyWith({
    String? id,
    SectionKind? kind,
    int? rows,
    List<JournalBlockData>? blocks,
    bool clearRows = false,
  }) => EntrySection(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    rows: clearRows ? null : (rows ?? this.rows),
    blocks: blocks ?? this.blocks,
  );

  @override
  String toString() =>
      'EntrySection(id: $id, kind: $kind, rows: $rows, blocks: ${blocks.length})';
}
