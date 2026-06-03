import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/delayed_tap_focus.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';

class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// Host's "push expanded route" callback. Wired into the
  /// `DelayedTapFocus` wrapper so the framework arena resolves
  /// single vs double tap without flashing the keyboard.
  final VoidCallback? onDoubleTap;

  /// True when this block is the active edit target. The mixin
  /// requests focus on the field when this flips false → true (used
  /// by the expanded route when the user taps inside to start
  /// editing). In normal mode (setting OFF) the field is always
  /// interactive via natural tap-to-focus; no AbsorbPointer wrapping.
  /// In setting ON grid mode the host (`BlockGrid`) wraps the whole
  /// tile in `IgnorePointer` so single-taps never reach this field —
  /// see [BlockGrid].
  final bool editing;

  /// True when rendered inside the expanded route. The editable field
  /// becomes scrollable so the full (uncapped) text is reachable; in the
  /// grid it stays clipped to the fixed 1×1 cell.
  final bool expanded;

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget>
    with TextContentControllerMixin<TextBlockWidget> {
  @override
  JournalBlockData get data => widget.data;

  @override
  ValueChanged<JournalBlockData>? get onChanged => widget.onChanged;

  @override
  bool get editing => widget.editing;

  @override
  Widget build(BuildContext context) {
    if (widget.mode == BlockMode.readOnly) {
      final content = TextBlockContent.fromMap(widget.data.content);
      final isEmpty = content.text.trim().isEmpty;
      final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        color: isEmpty ? Theme.of(context).disabledColor : null,
      );
      return Padding(
        padding: const EdgeInsets.all(12),
        // Text is uncapped on input but the 1×1 cell is fixed-size, so
        // truncate the read-only display to the number of lines that fit
        // and append an ellipsis. `LayoutBuilder` sees the chrome's
        // stable reference constraints (see block_chrome.dart).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lineHeight = TextPainter(
              text: TextSpan(text: 'A', style: style),
              textDirection: Directionality.of(context),
            ).preferredLineHeight;
            final maxLines = (constraints.maxHeight / lineHeight).floor().clamp(
              1,
              1 << 30,
            );
            return Text(
              isEmpty ? 'No text yet' : content.text,
              style: style,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      );
    }

    // Padding sits INSIDE the `DelayedTapFocus` GestureDetector so taps
    // anywhere in the 160 px chrome area (including the 12 px inset)
    // reach the focus handler — see the chrome's "padding lives inside
    // each block widget" comment in `block_chrome.dart`.
    return DelayedTapFocus(
      focusNode: focusNode,
      onDoubleTap: widget.onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox.expand(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            expands: true,
            maxLines: null,
            minLines: null,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            // Grid host clips overflow to the fixed 1×1 cell (the
            // chrome's antiAlias clipBehavior); the expanded route
            // scrolls so the full uncapped text is reachable.
            scrollPhysics: widget.expanded
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            decoration: const InputDecoration(
              hintText: 'Write something…',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: emitText,
          ),
        ),
      ),
    );
  }
}
