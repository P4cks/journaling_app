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

  /// Block tile width that matches a single tile in a 2-column
  /// `BlockGrid`: full section width minus the grid's 16px left + 16px
  /// right padding + 12px inter-column spacing, divided by 2. Clamped so
  /// it never gets absurd on very wide / very narrow viewports.
  static double _gridTileSize(double maxWidth) =>
      ((maxWidth - 44) / 2).clamp(120.0, 220.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final float = floatBlock;
    final content = TextBlockContent.fromMap(textBlock.content);
    final isEmpty = content.text.trim().isEmpty;
    final editable = mode == BlockMode.editable;

    // In editable mode an empty text block shows an actionable hint;
    // in read-only mode it mirrors the text section's "No text yet".
    final displayText = isEmpty
        ? (editable ? 'Tap to write…' : 'No text yet')
        : content.text;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
      color: isEmpty ? theme.disabledColor : null,
    );

    // Tapping the text (anywhere not on the float block) opens the
    // expanded editor. The float block sits deeper in the gesture arena
    // (its own GestureDetector inside BlockWidget wins for taps on it),
    // so this translucent tap only fires for the surrounding text.
    void Function()? onTextTap;
    if (editable && onRequestTextSectionEdit != null) {
      onTextTap = () => onRequestTextSectionEdit!(textBlock);
    }

    // No float block: plain full-width text. Editable still routes taps
    // to the expanded editor (read-only is inert).
    if (float == null) {
      final plain = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(displayText, style: textStyle),
      );
      if (onTextTap == null) return plain;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTextTap,
        child: plain,
      );
    }

    // Both modes render the same `Text.rich` + `WidgetSpan` float-wrap so
    // the text wraps around the block (magazine `float: left`). The
    // editable TextField can't live inside a WidgetSpan, so editing is
    // delegated to the expanded route via the surrounding tap.
    //
    // LayoutBuilder sits ABOVE the horizontal padding so `maxWidth` is the
    // full section width — `_gridTileSize` subtracts the grid's own
    // paddings to reproduce a real grid tile's width.
    final wrap = LayoutBuilder(
      builder: (context, constraints) {
        final blockSize = _gridTileSize(constraints.maxWidth);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text.rich(
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
          ),
        );
      },
    );

    if (onTextTap == null) return wrap;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTextTap,
      child: wrap,
    );
  }
}
