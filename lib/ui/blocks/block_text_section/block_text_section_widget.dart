import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_input_limits.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

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
/// **Editing** mirrors every other block: a single tap focuses an
/// in-place `TextField`; a double tap opens the expanded route. A
/// `TextField` can't wrap around an inline block, so while focused the
/// layout swaps to block-left + field-right (the block keeps its
/// position, so there's no jump); on blur it returns to the float-wrap
/// display, which reflows the text under the block.
///
/// The two blocks are passed in separately and looked up by the caller
/// by type, so their order inside `EntrySection.blocks` is irrelevant.
/// [floatBlock] is null when the layout template carried no float block.
class BlockTextSectionWidget extends StatefulWidget {
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

  /// Host's "engage text" callback (double-tap → expanded text route).
  final ValueChanged<JournalBlockData>? onRequestTextSectionEdit;

  @override
  State<BlockTextSectionWidget> createState() => _BlockTextSectionWidgetState();
}

class _BlockTextSectionWidgetState extends State<BlockTextSectionWidget>
    with TextContentControllerMixin<BlockTextSectionWidget> {
  /// True while the in-place `TextField` is mounted + focused. Driven to
  /// true by a single tap, back to false when the field loses focus.
  bool _editing = false;

  @override
  JournalBlockData get data => widget.textBlock;

  @override
  ValueChanged<JournalBlockData>? get onChanged => widget.onBlockChanged;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  // Leaving the field (Done / tap-outside) returns to the float-wrap
  // display. Entering edit mode is driven by the tap handler, so only
  // react to focus loss here.
  void _onFocusChange() {
    if (mounted && _editing && !focusNode.hasFocus) {
      setState(() => _editing = false);
    }
  }

  void _enterEdit() {
    if (!_editing) setState(() => _editing = true);
  }

  Widget _buildFloatBlock(BuildContext context, JournalBlockData block) {
    final canDoubleTap =
        widget.mode == BlockMode.editable &&
        widget.onRequestBlockEdit != null &&
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
            mode: widget.mode,
            onChanged: widget.onBlockChanged,
            onJumpToDate: widget.onJumpToDate,
            onInteractionLockChanged: widget.onLockChanged,
            onDoubleTap: canDoubleTap
                ? () => widget.onRequestBlockEdit!(block)
                : null,
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
    final float = widget.floatBlock;
    final content = TextBlockContent.fromMap(widget.textBlock.content);
    final isEmpty = content.text.trim().isEmpty;
    final editable = widget.mode == BlockMode.editable;

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

        // Editable + focused → inline editor (a TextField can't wrap
        // around the block, so editing swaps to block-left + field-right;
        // the block keeps its position so there's no jump).
        if (editable && _editing) {
          return _buildEditor(context, theme, float, blockSize);
        }

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

        if (!editable) return display;

        // Single tap → inline edit; double tap → expanded route. The
        // translucent behaviour lets taps on the float block reach its
        // own gesture detector (engage / expand the block) — only taps
        // on the surrounding text fall through to these handlers.
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _enterEdit,
          onDoubleTap: widget.onRequestTextSectionEdit == null
              ? null
              : () => widget.onRequestTextSectionEdit!(widget.textBlock),
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
        .getPositionForOffset(Offset(0, blockSize + _bottomGap))
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

  /// In-place editor shown while the text field is focused. A
  /// `TextField` can't flow around the block, so the block stays
  /// floated-left and the field fills the column to its right.
  Widget _buildEditor(
    BuildContext context,
    ThemeData theme,
    JournalBlockData? float,
    double blockSize,
  ) {
    final debug = AppDependencies.of(context).debugSettings;
    final field = ListenableBuilder(
      listenable: debug,
      builder: (context, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        maxLines: null,
        minLines: float == null ? 4 : (blockSize / 24).floor().clamp(4, 8),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: theme.textTheme.bodyMedium,
        maxLength: BlockInputLimits.of(debug).textSectionChars,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: buildCharCounter(),
        decoration: const InputDecoration(
          hintText: 'Write something…',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: emitText,
      ),
    );

    if (float == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 12),
        child: field,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: _gap, bottom: _bottomGap),
            child: SizedBox(
              width: blockSize,
              height: blockSize,
              child: _buildFloatBlock(context, float),
            ),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }
}
