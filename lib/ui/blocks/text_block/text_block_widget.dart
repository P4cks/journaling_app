import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

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

class _TextBlockWidgetState extends State<TextBlockWidget>
    with TextContentControllerMixin<TextBlockWidget> {
  @override
  JournalBlockData get data => widget.data;

  @override
  ValueChanged<JournalBlockData>? get onChanged => widget.onChanged;

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

    final blockSettings = AppDependencies.of(context).blockSettings;

    return ListenableBuilder(
      listenable: blockSettings,
      builder: (context, _) => _buildEditableField(context, blockSettings),
    );
  }

  Widget _buildEditableField(BuildContext context, BlockSettings settings) {
    final limit = settings.textCharLimit;
    return Stack(
      children: [
        SizedBox.expand(
          child: TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            maxLength: limit,
            // Suppress the default Material counter — we render our own
            // in the corner so it doesn't reserve vertical space below
            // the input.
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => null,
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
        if (limit != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Text(
                  '${controller.text.characters.length}/$limit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
