import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/prompt_block/prompt_picker_sheet.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

class PromptBlockWidget extends StatefulWidget {
  const PromptBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.editing = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// True when this block is the active edit target. Focuses the answer
  /// field; gates inner pointer events so single taps are inert.
  final bool editing;

  @override
  State<PromptBlockWidget> createState() => _PromptBlockWidgetState();
}

class _PromptBlockWidgetState extends State<PromptBlockWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _autoPromptShown = false;
  bool _wasEditing = false;

  @override
  void initState() {
    super.initState();
    final content = PromptBlockContent.fromMap(widget.data.content);
    _controller = TextEditingController(text: content.answer);
    _focusNode = FocusNode();
    _wasEditing = widget.editing;
    // No initial-mount auto-focus — see TextContentControllerMixin's
    // comment. Auto-focus only fires on the false → true `editing`
    // transition handled in didUpdateWidget.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mode != BlockMode.editable) return;
    if (_autoPromptShown) return;
    final content = PromptBlockContent.fromMap(widget.data.content);
    if (content.prompt.trim().isNotEmpty) return;
    _autoPromptShown = true;
    // Modals must not be opened directly from didChangeDependencies —
    // schedule for after the current build frame completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPicker(initial: true);
    });
  }

  @override
  void didUpdateWidget(covariant PromptBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final content = PromptBlockContent.fromMap(widget.data.content);
    if (oldWidget.data.id != widget.data.id) {
      _controller.text = content.answer;
    } else if (_controller.text != content.answer) {
      // External update (e.g. the expanded-block route mirror) wrote a
      // new answer for the same block. Per-keystroke edits from this
      // controller can't reach this branch because the parent rebuild
      // arrives with `content.answer == _controller.text`. Reposition
      // the caret at the end so paste/full-replace doesn't strand it
      // beyond the new length.
      _controller.value = TextEditingValue(
        text: content.answer,
        selection: TextSelection.collapsed(offset: content.answer.length),
      );
    }
    if (widget.editing != _wasEditing) {
      _wasEditing = widget.editing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.editing) {
          _focusNode.requestFocus();
        } else if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _emit({required String prompt, required String answer}) {
    final updated = widget.data.copyWith(
      content: PromptBlockContent(prompt: prompt, answer: answer).toMap(),
    );
    widget.onChanged?.call(updated);
  }

  Future<void> _openPicker({required bool initial}) async {
    final settings = AppDependencies.of(context).blockSettings;
    final currentContent = PromptBlockContent.fromMap(widget.data.content);
    final currentPrompt = currentContent.prompt.trim();
    final picked = await showPromptPickerSheet(
      context,
      prompts: settings.prompts,
      selected: currentPrompt.isEmpty ? null : currentPrompt,
    );
    if (!mounted) return;
    if (picked == null) return;
    if (picked == currentContent.prompt) return;

    final currentAnswer = currentContent.answer;
    if (!initial && currentAnswer.trim().isNotEmpty) {
      final keep = await _confirmAnswerOnRepick();
      if (!mounted) return;
      if (keep == null) return; // dismissed → no-op
      if (keep) {
        _emit(prompt: picked, answer: currentAnswer);
      } else {
        _controller.text = '';
        _emit(prompt: picked, answer: '');
      }
      return;
    }

    _emit(prompt: picked, answer: currentAnswer);
  }

  Future<bool?> _confirmAnswerOnRepick() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change prompt?'),
        content: const Text(
          'You already typed an answer. Keep it under the new prompt, or clear it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Clear it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keep'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = PromptBlockContent.fromMap(widget.data.content);
    final prompt = content.prompt.trim();
    final scheme = theme.colorScheme;
    final isEditable = widget.mode == BlockMode.editable;

    final promptLabel = prompt.isEmpty
        ? Text(
            isEditable ? 'Tap to pick a prompt' : 'No prompt set',
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

    Widget body;
    if (!isEditable) {
      final answer = content.answer.trim();
      final isEmpty = answer.isEmpty;
      body = Column(
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
    } else if (prompt.isEmpty) {
      // Editable but no prompt yet — show a tap-target so the user can
      // re-open the picker. Single tap on the body opens the picker
      // (natural taps reach this widget in normal mode; in setting
      // ON's grid the host wraps everything in IgnorePointer).
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPicker(initial: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            promptLabel,
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  'Tap to choose',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          promptLabel,
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
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
              onChanged: (value) =>
                  _emit(prompt: content.prompt, answer: value),
            ),
          ),
        ],
      );
    }

    if (!isEditable) return body;

    // Long-press to re-pick. Always-on in editable mode — single-tap
    // semantics handle focus / picker-open naturally.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _openPicker(initial: false),
      child: body,
    );
  }
}
