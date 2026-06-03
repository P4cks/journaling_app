import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_section/text_section_widget.dart';

/// Renders a `SectionKind.blockTextBody` section: a photo/memory block
/// floated top-left with text wrapping to its right and then full-width
/// beneath it (magazine `float: left`).
///
/// The float-wrap is the **read-mode** rendering, built with
/// `Text.rich` + `WidgetSpan(alignment: PlaceholderAlignment.top)` — the
/// canonical "text wraps around image" trick, with zero new dependency.
/// In editable mode the text is a plain full-width [TextSectionWidget]
/// stacked beneath the (still tappable) float block — consistent with
/// how text sections already separate edit (field) from display.
///
/// The two blocks are passed in separately and looked up by the caller
/// by type, so their order inside `EntrySection.blocks` is irrelevant.
/// [floatBlock] is null when the layout template carried no float block.
class BlockTextSectionWidget extends StatelessWidget {
  const BlockTextSectionWidget({
    super.key,
    required this.floatBlock,
    required this.textBlock,
    required this.mode,
    this.onBlockChanged,
    this.onJumpToDate,
    this.onLockChanged,
    this.onRequestBlockEdit,
    this.onRequestTextSectionEdit,
    this.textEditing = false,
  });

  /// The floated photo/memory block, or null when none was configured.
  final JournalBlockData? floatBlock;

  /// The wrapping text block (always present; reuses `TextBlockContent`).
  final JournalBlockData textBlock;

  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onBlockChanged;
  final ValueChanged<DateTime>? onJumpToDate;
  final void Function(String, bool)? onLockChanged;

  /// Host's "engage float block" callback (double-tap → expand / fire).
  final ValueChanged<JournalBlockData>? onRequestBlockEdit;

  /// Host's "engage text" callback (double-tap → expanded text route).
  final ValueChanged<JournalBlockData>? onRequestTextSectionEdit;

  /// True when the text block is the active in-place edit target.
  final bool textEditing;

  Widget _buildFloatBlock(BuildContext context, JournalBlockData block) {
    final canDoubleTap =
        mode == BlockMode.editable &&
        onRequestBlockEdit != null &&
        block.type.usesEditMode;
    return Hero(
      tag: blockHeroTag(block.id),
      child: Material(
        // Hero-flight Material ancestor (see block_grid.dart).
        type: MaterialType.transparency,
        child: BlockChrome(
          visuals: block.visuals,
          child: BlockWidget(
            key: ValueKey(block.id),
            data: block,
            mode: mode,
            onChanged: onBlockChanged,
            onJumpToDate: onJumpToDate,
            onInteractionLockChanged: onLockChanged,
            onDoubleTap: canDoubleTap ? () => onRequestBlockEdit!(block) : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final float = floatBlock;

    if (mode == BlockMode.readOnly) {
      final content = TextBlockContent.fromMap(textBlock.content);
      final isEmpty = content.text.trim().isEmpty;
      final textStyle = theme.textTheme.bodyMedium?.copyWith(
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        color: isEmpty ? theme.disabledColor : null,
      );
      final displayText = isEmpty ? 'No text yet' : content.text;

      if (float == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(displayText, style: textStyle),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final blockSize = (constraints.maxWidth * 0.42).clamp(120.0, 200.0);
            return Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.top,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: SizedBox(
                        width: blockSize,
                        height: blockSize,
                        child: _buildFloatBlock(context, float),
                      ),
                    ),
                  ),
                  TextSpan(text: displayText, style: textStyle),
                ],
              ),
            );
          },
        ),
      );
    }

    // Editable: the float block (still tappable to configure) stacked
    // above a plain full-width text field.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (float != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final blockSize = (constraints.maxWidth * 0.5).clamp(
                      140.0,
                      220.0,
                    );
                    return SizedBox(
                      width: blockSize,
                      height: blockSize,
                      child: _buildFloatBlock(context, float),
                    );
                  },
                ),
              ),
            ),
          TextSectionWidget(
            key: ValueKey(textBlock.id),
            data: textBlock,
            mode: mode,
            onChanged: onBlockChanged,
            editing: textEditing,
            onDoubleTap: onRequestTextSectionEdit == null
                ? null
                : () => onRequestTextSectionEdit!(textBlock),
          ),
        ],
      ),
    );
  }
}
