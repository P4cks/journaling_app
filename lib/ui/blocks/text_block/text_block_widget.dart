import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';

class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final content = TextBlockContent.fromMap(widget.data.content);
    _controller = TextEditingController(text: content.text);
  }

  @override
  void didUpdateWidget(covariant TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id) {
      final content = TextBlockContent.fromMap(widget.data.content);
      _controller.text = content.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(String value) {
    final updated = JournalBlockData.create(
      id: widget.data.id,
      type: widget.data.type,
      content: TextBlockContent(text: value).toMap(),
    );
    widget.onChanged?.call(updated);
  }

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
        controller: _controller,
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
        onChanged: _emit,
      ),
    );
  }
}
