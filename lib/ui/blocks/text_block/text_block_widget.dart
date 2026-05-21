import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';

class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.editing = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// True when this block is the active edit target. The mixin
  /// requests focus on the field when this flips false → true (used
  /// by the expanded route when the user taps inside to start
  /// editing). In normal mode (setting OFF) the field is always
  /// interactive via natural tap-to-focus; no AbsorbPointer wrapping.
  /// In setting ON grid mode the host (`BlockGrid`) wraps the whole
  /// tile in `IgnorePointer` so single-taps never reach this field —
  /// see [BlockGrid].
  final bool editing;

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
      return Text(
        isEmpty ? 'No text yet' : content.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          color: isEmpty ? Theme.of(context).disabledColor : null,
        ),
      );
    }

    return SizedBox.expand(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: 'Write something…',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: emitText,
      ),
    );
  }
}
