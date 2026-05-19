import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';

/// Full-width text section. Backs onto the same `TextBlockContent`
/// shape as `TextBlockWidget` so it round-trips through the journal
/// entry's section blocks list, but renders without a `BlockCard`
/// chrome — grows with its content. No cap on input length.
class TextSectionWidget extends StatefulWidget {
  const TextSectionWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
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
    );
  }
}
