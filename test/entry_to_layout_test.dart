import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/entry_section.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/layouts/entry_to_layout.dart';

JournalBlockData _block(
  String id,
  BlockType type, {
  Map<String, dynamic>? content,
}) => JournalBlockData.create(id: id, type: type, content: content ?? const {});

void main() {
  group('layoutFromSections', () {
    test('always produces a custom layout', () {
      final layout = layoutFromSections(const []);
      expect(layout.kind, LayoutKind.custom);
      expect(layout.sections, isEmpty);
    });

    test('drops the implicit text block of text/header sections', () {
      final sections = [
        EntrySection(
          id: 's-text',
          kind: SectionKind.text,
          blocks: [_block('b1', BlockType.textBlock)],
        ),
        EntrySection(
          id: 's-header',
          kind: SectionKind.header,
          blocks: [_block('b2', BlockType.textBlock)],
        ),
      ];
      final layout = layoutFromSections(sections);
      expect(layout.sections, hasLength(2));
      expect(layout.sections[0].kind, SectionKind.text);
      expect(layout.sections[0].blocks, isEmpty);
      expect(layout.sections[1].kind, SectionKind.header);
      expect(layout.sections[1].blocks, isEmpty);
    });

    test('keeps every block-grid slot and preserves rows', () {
      final sections = [
        EntrySection(
          id: 's-grid',
          kind: SectionKind.blockGrid,
          rows: 2,
          blocks: [
            _block('g1', BlockType.textBlock),
            _block('g2', BlockType.moodTracker),
          ],
        ),
      ];
      final layout = layoutFromSections(sections);
      final section = layout.sections.single;
      expect(section.kind, SectionKind.blockGrid);
      expect(section.rows, 2);
      expect(section.blocks.map((b) => b.type), [
        BlockType.textBlock,
        BlockType.moodTracker,
      ]);
    });

    test('threads custom-carousel definitionId into the template config', () {
      final sections = [
        EntrySection(
          id: 's-grid',
          kind: SectionKind.blockGrid,
          rows: 1,
          blocks: [
            _block(
              'c1',
              BlockType.customCarousel,
              content: const CustomCarouselBlockContent(
                definitionId: 'def-7',
              ).toMap(),
            ),
          ],
        ),
      ];
      final layout = layoutFromSections(sections);
      final template = layout.sections.single.blocks.single;
      expect(template.type, BlockType.customCarousel);
      expect(template.config['definitionId'], 'def-7');
    });

    test(
      'keeps only the float of a blockTextBody section, dropping the body',
      () {
        final withFloat = EntrySection(
          id: 's-bt',
          kind: SectionKind.blockTextBody,
          blocks: [
            _block('float', BlockType.photoBlock),
            _block('body', BlockType.textBlock),
          ],
        );
        final textOnly = EntrySection(
          id: 's-bt2',
          kind: SectionKind.blockTextBody,
          blocks: [_block('body2', BlockType.textBlock)],
        );
        final layout = layoutFromSections([withFloat, textOnly]);
        expect(layout.sections[0].blocks.map((b) => b.type), [
          BlockType.photoBlock,
        ]);
        expect(layout.sections[1].blocks, isEmpty);
      },
    );

    test('carries the wannado definitionId and carries no blocks', () {
      final sections = [
        const EntrySection(
          id: 's-w',
          kind: SectionKind.wannado,
          blocks: [],
          definitionId: 'wanna-3',
        ),
        const EntrySection(id: 's-d', kind: SectionKind.divider, blocks: []),
      ];
      final layout = layoutFromSections(sections);
      expect(layout.sections[0].kind, SectionKind.wannado);
      expect(layout.sections[0].definitionId, 'wanna-3');
      expect(layout.sections[0].blocks, isEmpty);
      expect(layout.sections[1].kind, SectionKind.divider);
    });
  });
}
