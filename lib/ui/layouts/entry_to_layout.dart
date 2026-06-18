import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/entry_section.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/layout_section.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Builds a transient [JournalLayout] (always [LayoutKind.custom]) that
/// describes the structure of [sections] — the inverse of
/// `JournalRepository.materializeLayout`. Used to seed the per-day custom
/// layout editor (GUS-65) from an existing entry so the user tweaks their
/// current structure rather than starting from scratch.
///
/// The mapping mirrors `materializeLayout` so a round-trip is stable: the
/// "implicit" materialised blocks (the text block of a `text`/`header`
/// section, the trailing body text of a `blockTextBody`) are **not** slots
/// in the layout, so they are dropped here. Grid / feature / float blocks
/// become one [BlockTemplate] each; `customCarousel` / `habitTracker`
/// blocks thread their `definitionId` back into `BlockTemplate.config` the
/// same way the editor and materialize do.
JournalLayout layoutFromSections(List<EntrySection> sections) {
  return JournalLayout(
    id: _uuid.v4(),
    name: 'Custom',
    kind: LayoutKind.custom,
    sections: [for (final section in sections) _sectionFromEntry(section)],
  );
}

LayoutSection _sectionFromEntry(EntrySection section) {
  switch (section.kind) {
    case SectionKind.text:
    case SectionKind.header:
    case SectionKind.divider:
      // Carry no slots — the materialised text block (text/header) is
      // implicit, and dividers are purely visual.
      return LayoutSection(id: section.id, kind: section.kind, blocks: const []);
    case SectionKind.wannado:
      return LayoutSection(
        id: section.id,
        kind: SectionKind.wannado,
        blocks: const [],
        definitionId: section.definitionId,
      );
    case SectionKind.blockGrid:
      return LayoutSection(
        id: section.id,
        kind: SectionKind.blockGrid,
        rows: section.rows,
        blocks: [for (final block in section.blocks) _templateFromBlock(block)],
      );
    case SectionKind.featureBlock:
      return LayoutSection(
        id: section.id,
        kind: SectionKind.featureBlock,
        blocks: section.blocks.isEmpty
            ? const []
            : [_templateFromBlock(section.blocks.first)],
      );
    case SectionKind.blockTextBody:
      // Materialised as `[if float present: float, bodyText]` — the body
      // text is always last and is implicit, so keep only the float.
      final float = section.blocks.length > 1 ? section.blocks.first : null;
      return LayoutSection(
        id: section.id,
        kind: SectionKind.blockTextBody,
        blocks: float == null ? const [] : [_templateFromBlock(float)],
      );
  }
}

BlockTemplate _templateFromBlock(JournalBlockData block) {
  final isDefinitionBacked =
      block.type == BlockType.customCarousel ||
      block.type == BlockType.habitTracker;
  final defId = isDefinitionBacked
      ? block.content['definitionId'] as String?
      : null;
  return BlockTemplate.create(
    id: block.id,
    type: block.type,
    config: defId == null ? const {} : {'definitionId': defId},
  );
}
