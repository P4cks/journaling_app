import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_input_limits.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/text_content_controller_mixin.dart';

/// Single-line heading section (`SectionKind.header`, GUS-6, FREE).
///
/// Backed by the same `TextBlockContent` (`{"text": "..."}`) shape as
/// the 1×1 text block and the full-width text section — so it reuses the
/// existing JSON path + emptiness classification without a new content
/// type. Renders a large bold one-liner in `BlockMode.readOnly` (with an
/// italic "Heading" placeholder when empty) and a capped single-line
/// `TextField` in `BlockMode.editable`.
///
/// Unlike `TextSectionWidget` there is no expanded route and no Hero:
/// a heading is a single short line, so it edits directly in place via
/// the same `editingBlockId` path the text section uses, but the field
/// is tappable directly (no `DelayedTapFocus` two-tap dance).
class HeaderSectionWidget extends StatefulWidget {
  const HeaderSectionWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.editing = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final bool editing;

  @override
  State<HeaderSectionWidget> createState() => _HeaderSectionWidgetState();
}

class _HeaderSectionWidgetState extends State<HeaderSectionWidget>
    with TextContentControllerMixin<HeaderSectionWidget> {
  @override
  JournalBlockData get data => widget.data;

  @override
  ValueChanged<JournalBlockData>? get onChanged => widget.onChanged;

  @override
  bool get editing => widget.editing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    if (widget.mode == BlockMode.readOnly) {
      final content = TextBlockContent.fromMap(widget.data.content);
      final isEmpty = content.text.trim().isEmpty;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          isEmpty ? 'Heading' : content.text,
          style: style?.copyWith(
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            color: isEmpty ? theme.disabledColor : null,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: 1,
        textCapitalization: TextCapitalization.sentences,
        style: style,
        maxLength: kHeaderSectionMaxChars,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: buildCharCounter(onlyWhenFocused: true),
        decoration: const InputDecoration(
          hintText: 'Heading',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: emitText,
      ),
    );
  }
}
