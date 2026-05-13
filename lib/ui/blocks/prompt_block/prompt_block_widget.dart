import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';

class PromptBlockWidget extends StatefulWidget {
  const PromptBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<PromptBlockWidget> createState() => _PromptBlockWidgetState();
}

class _PromptBlockWidgetState extends State<PromptBlockWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final content = PromptBlockContent.fromMap(widget.data.content);
    _controller = TextEditingController(text: content.answer);
  }

  @override
  void didUpdateWidget(covariant PromptBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id) {
      final content = PromptBlockContent.fromMap(widget.data.content);
      _controller.text = content.answer;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(String value, {required String prompt}) {
    final updated = JournalBlockData.create(
      id: widget.data.id,
      type: widget.data.type,
      content: PromptBlockContent(prompt: prompt, answer: value).toMap(),
    );
    widget.onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = PromptBlockContent.fromMap(widget.data.content);
    final prompt = content.prompt.trim();
    final scheme = theme.colorScheme;

    final promptLabel = prompt.isEmpty
        ? Text(
            'No prompt set',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
              fontStyle: FontStyle.italic,
            ),
          )
        : Text(
            prompt,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
              height: 1.25,
            ),
          );

    if (widget.mode == BlockMode.readOnly) {
      final answer = content.answer.trim();
      final isEmpty = answer.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          promptLabel,
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              isEmpty ? 'Not answered yet' : content.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                color: isEmpty ? theme.disabledColor : null,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        promptLabel,
        const SizedBox(height: 6),
        Expanded(
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            minLines: null,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Your answer…',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _emit(value, prompt: content.prompt),
          ),
        ),
      ],
    );
  }
}
