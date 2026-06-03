import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/delayed_tap_focus.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';

/// Full-width text section. Backs onto the same `TextBlockContent`
/// shape as `TextBlockWidget` so it round-trips through the journal
/// entry's section blocks list, but renders without a `BlockCard`
/// chrome — grows with its content. Input is uncapped (long-form
/// content lives in sections; the in-grid field grows and the expanded
/// route scrolls).
class TextSectionWidget extends StatefulWidget {
  const TextSectionWidget({
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
  /// `DelayedTapFocus` wrapper (grid variant only).
  final VoidCallback? onDoubleTap;

  /// True when this section is the active edit target. Drives the
  /// mixin's focus handoff. In the expanded route this stays true
  /// from mount; in-grid it tracks user interaction.
  final bool editing;

  /// True when rendered inside the expanded route. Per the design
  /// rule: in the expanded view the section has NO rectangular
  /// background or outline — just text on the blurred backdrop, with
  /// content aligned top-left and the `TextField` filling the
  /// available space (`expands: true`).
  final bool expanded;

  @override
  State<TextSectionWidget> createState() => _TextSectionWidgetState();
}

class _TextSectionWidgetState extends State<TextSectionWidget>
    with TextContentControllerMixin<TextSectionWidget> {
  @override
  JournalBlockData get data => widget.data;

  @override
  ValueChanged<JournalBlockData>? get onChanged => widget.onChanged;

  @override
  bool get editing => widget.editing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.mode == BlockMode.readOnly) {
      final content = TextBlockContent.fromMap(widget.data.content);
      final isEmpty = content.text.trim().isEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          isEmpty ? 'No text yet' : content.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            color: isEmpty ? theme.disabledColor : null,
          ),
        ),
      );
    }

    if (widget.expanded) {
      // Expanded-route variant: no card chrome, no outline. Text fills
      // the parent constraints; top-left alignment for natural
      // long-form journal entry feel.
      return TextField(
        controller: controller,
        focusNode: focusNode,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textAlignVertical: TextAlignVertical.top,
        textAlign: TextAlign.start,
        style: theme.textTheme.bodyLarge,
        decoration: const InputDecoration(
          hintText: 'Write something…',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: emitText,
      );
    }

    // In-grid editable variant: bounded by content. `DelayedTapFocus`
    // wraps the field so single-tap delays ~300 ms (lets a possible
    // double-tap take over and push the expanded route without the
    // keyboard flashing up first).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DelayedTapFocus(
        focusNode: focusNode,
        onDoubleTap: widget.onDoubleTap,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          minLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write something…',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: emitText,
        ),
      ),
    );
  }
}
