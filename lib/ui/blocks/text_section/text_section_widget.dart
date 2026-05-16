import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Full-width text section. Backs onto the same `TextBlockContent`
/// shape as `TextBlockWidget` so it round-trips through the journal
/// entry's section blocks list, but renders without a `BlockCard`
/// chrome — grows with its content and respects
/// `BlockSettings.textCharLimit`.
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

class _TextSectionWidgetState extends State<TextSectionWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final content = TextBlockContent.fromMap(widget.data.content);
    _controller = TextEditingController(text: content.text);
  }

  @override
  void didUpdateWidget(covariant TextSectionWidget oldWidget) {
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

    final blockSettings = AppDependencies.of(context).blockSettings;
    return ListenableBuilder(
      listenable: blockSettings,
      builder: (context, _) => _buildEditable(context, blockSettings),
    );
  }

  Widget _buildEditable(BuildContext context, BlockSettings settings) {
    final theme = Theme.of(context);
    final limit = settings.textCharLimit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            minLines: 4,
            maxLength: limit,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write something…',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _emit,
          ),
          if (limit != null)
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Text(
                    '${_controller.text.characters.length}/$limit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
