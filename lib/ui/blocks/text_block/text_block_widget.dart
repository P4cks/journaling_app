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

  /// True when this block is the active edit target. The mixin focuses
  /// the field; we also drop the AbsorbPointer wrapper so taps reach
  /// the TextField (re-cursor, select). When false the field is
  /// pointer-absorbed so single-taps don't focus it — the new
  /// double-tap-to-edit gesture, handled at the grid level, is the only
  /// way in.
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

    return AbsorbPointer(
      absorbing: !widget.editing,
      child: SizedBox.expand(
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
      ),
    );
  }
}
