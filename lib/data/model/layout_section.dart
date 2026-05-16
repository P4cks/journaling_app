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
///
/// `BlockTemplate.configJson` is currently always `'{}'` — see
/// [block_template.dart] for the forward-compat reasoning.
class LayoutSection {
  final String id;
  final SectionKind kind;
  final int? rows;
  final List<BlockTemplate> blocks;

  const LayoutSection({
    required this.id,
    required this.kind,
    required this.blocks,
    this.rows,
  });

  LayoutSection copyWith({
    String? id,
    SectionKind? kind,
    int? rows,
    List<BlockTemplate>? blocks,
    bool clearRows = false,
  }) => LayoutSection(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    rows: clearRows ? null : (rows ?? this.rows),
    blocks: blocks ?? this.blocks,
  );

  @override
  String toString() =>
      'LayoutSection(id: $id, kind: $kind, rows: $rows, blocks: ${blocks.length})';
}
