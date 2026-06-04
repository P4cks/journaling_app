import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';

/// Renders a `SectionKind.blockTextBody` section: a photo/memory block
/// floated top-left with text wrapping around it (magazine `float:
/// left`) and then full-width beneath — a genuine multi-line float.
///
/// **Display** measures how many lines fit beside the block (via a
/// `TextPainter` at the narrow beside-width) and splits the text in
/// two: the `beside` part renders in a `Row` next to the block, the
/// `below` part flows full-width underneath. This is what makes the
/// text keep using the space to the right of the block over multiple
/// lines instead of dropping under it after one line — Flutter's
/// `WidgetSpan` float only wraps the first line, so it is NOT used.
///
/// **Editing** is delegated to the expanded route: a `TextField` can't
/// flow around an inline block, and an in-place narrow-column editor
/// reflows the text awkwardly on blur, so a tap on the text opens the
/// expanded editor directly (where the text gets the full width).
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

  /// Host's "engage text" callback (tap → expanded text route).
  final ValueChanged<JournalBlockData>? onRequestTextSectionEdit;

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

  static const double _hPad = 16.0;
  static const double _gap = 12.0;
  static const double _bottomGap = 8.0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final blockSize = _gridTileSize(maxWidth);

        final display = float == null
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _hPad,
                  vertical: 12,
                ),
                child: Text(displayText, style: textStyle),
              )
            : _buildFloatWrap(
                context,
                maxWidth,
                blockSize,
                float,
                displayText,
                textStyle,
              );

        if (!editable || onRequestTextSectionEdit == null) return display;

        // A tap on the text opens the expanded editor directly (a
        // TextField can't wrap around the inline block, so editing is
        // delegated rather than done in place). The translucent
        // behaviour lets taps on the float block reach its own gesture
        // detector — only taps on the surrounding text fall through.
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onRequestTextSectionEdit!(textBlock),
          child: display,
        );
      },
    );
  }

  /// The multi-line float: measure how much text fits beside the block
  /// (within its height), render that in a `Row` next to the block, and
  /// flow the remainder full-width underneath.
  Widget _buildFloatWrap(
    BuildContext context,
    double maxWidth,
    double blockSize,
    JournalBlockData float,
    String displayText,
    TextStyle? textStyle,
  ) {
    final contentWidth = maxWidth - _hPad * 2;
    final besideWidth = contentWidth - blockSize - _gap;

    final blockChild = Padding(
      padding: const EdgeInsets.only(right: _gap, bottom: _bottomGap),
      child: SizedBox(
        width: blockSize,
        height: blockSize,
        child: _buildFloatBlock(context, float),
      ),
    );

    // Too little room beside the block → stack it above full-width text
    // instead of cramming text into a sliver.
    if (besideWidth < 48) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            blockChild,
            Text(displayText, style: textStyle),
          ],
        ),
      );
    }

    // Find the character offset where the text passes the block's bottom
    // (laid out at the narrow beside-width). `getPositionForOffset` at
    // x=0 snaps to the start of the line at that height, so the split
    // always lands on a line boundary — the lines above stay beside the
    // block, the rest flow full-width below.
    final painter = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: besideWidth);
    final split = painter
        .getPositionForOffset(Offset(0, blockSize))
        .offset;
    painter.dispose();

    final beside = displayText.substring(0, split);
    final below = displayText.substring(split);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              blockChild,
              Expanded(child: Text(beside, style: textStyle)),
            ],
          ),
          if (below.isNotEmpty) Text(below, style: textStyle),
        ],
      ),
    );
  }
}
