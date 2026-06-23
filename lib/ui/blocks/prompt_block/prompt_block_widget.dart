import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/delayed_tap_focus.dart';
import 'package:journaling_app_rewrite/ui/blocks/prompt_block/prompt_picker_sheet.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

class PromptBlockWidget extends StatefulWidget {
  const PromptBlockWidget({
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

  /// Host's "push expanded route" callback. Wired into the answer
  /// field's `DelayedTapFocus` wrapper.
  final VoidCallback? onDoubleTap;

  /// True when this block is the active edit target. Focuses the answer
  /// field; gates inner pointer events so single taps are inert.
  final bool editing;

  /// True when rendered inside the expanded route. The answer field
  /// becomes scrollable so the full (uncapped) text is reachable; in the
  /// grid it stays clipped to the fixed 1×1 cell.
  final bool expanded;

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
      onSaveToRotation: (prompt) async {
        // The sheet only invokes this when the prompt isn't already in
        // the list, but guard anyway so a stale list never double-adds.
        if (settings.prompts.contains(prompt)) return;
        await settings.setPrompts([...settings.prompts, prompt]);
      },
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
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(null),
            label: 'Cancel',
          ),
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Clear it',
          ),
          AppButton(
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: 'Keep',
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

    final promptText = prompt.isEmpty
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

    // In editable mode with a prompt set, surface a small pencil
    // affordance next to the prompt label so the user can re-pick. The
    // previous long-press affordance raced `BlockGrid`'s
    // `LongPressDraggable` for the gesture, so dragging-to-reorder a
    // prompt tile would silently open the picker. The pencil button
    // owns its tap target and the rest of the tile is free to drag.
    // When the prompt is empty the body itself is tappable (the
    // "Tap to choose" state), so the icon is suppressed to avoid two
    // affordances for the same action.
    final canRepick = isEditable && prompt.isNotEmpty;
    final promptLabel = canRepick
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: promptText),
              const SizedBox(width: 4),
              SizedBox(
                width: 22,
                height: 22,
                child: IconButton(
                  tooltip: 'Change prompt',
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  onPressed: () => _openPicker(initial: false),
                  icon: AppIcon(
                    HugeIcons.strokeRoundedPencil,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          )
        : promptText;

    Widget body;
    if (!isEditable) {
      final answer = content.answer.trim();
      final isEmpty = answer.isEmpty;
      final answerStyle = theme.textTheme.bodyMedium?.copyWith(
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        color: isEmpty ? theme.disabledColor : null,
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          promptLabel,
          const SizedBox(height: 6),
          // Answer is uncapped on input but the cell is fixed-size, so
          // truncate the read-only display to what fits + ellipsis.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final lineHeight = TextPainter(
                  text: TextSpan(text: 'A', style: answerStyle),
                  textDirection: Directionality.of(context),
                ).preferredLineHeight;
                final maxLines = (constraints.maxHeight / lineHeight)
                    .floor()
                    .clamp(1, 1 << 30);
                return Text(
                  isEmpty ? 'Not answered yet' : content.answer,
                  style: answerStyle,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      );
    } else if (prompt.isEmpty) {
      // Editable but no prompt yet. Single tap → picker (after
      // ~300 ms so a double tap can intercept). Double tap → host's
      // route push.
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPicker(initial: false),
        onDoubleTap: widget.onDoubleTap,
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
            child: DelayedTapFocus(
              focusNode: _focusNode,
              onDoubleTap: widget.onDoubleTap,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                // Grid clips to the fixed cell; expanded route scrolls
                // so the full uncapped answer is reachable.
                scrollPhysics: widget.expanded
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
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
          ),
        ],
      );
    }

    // Same padding for read-only and editable — no outer gesture
    // wrapper. Re-picking the prompt goes through the inline pencil
    // button rendered next to the prompt label (see `promptLabel`
    // above). Single-tap on the answer field focuses via
    // `DelayedTapFocus`; long-press passes through to `BlockGrid`'s
    // drag-to-reorder.
    return Padding(padding: const EdgeInsets.all(12), child: body);
  }
}
