import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// AppBar title field for the merged journal screen.
///
/// Renders the entry's user-supplied title (falling back to the formatted
/// date) on the primary line. Tapping swaps in an inline `TextField` so
/// the title can be edited without leaving the screen.
///
/// `onChanged` is called with the raw value on submit; the parent VM
/// normalizes empty/whitespace → null (date fallback). The date subtitle
/// is rendered by [JournalTitle] underneath this widget, not here.
class EditorTitle extends StatefulWidget {
  const EditorTitle({
    super.key,
    required this.title,
    required this.date,
    required this.editable,
    required this.onChanged,
  });

  final String? title;
  final DateTime date;
  final bool editable;
  final ValueChanged<String?> onChanged;

  @override
  State<EditorTitle> createState() => _EditorTitleState();
}

class _EditorTitleState extends State<EditorTitle> {
  bool _isEditing = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant EditorTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the controller when the entry's title changes externally
    // (e.g. via the layout-picker confirm replacing the entry, or a
    // swipe between days). Don't stomp the text while the user is
    // actively editing.
    if (!_isEditing && (widget.title ?? '') != _controller.text) {
      _controller.text = widget.title ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.editable) return;
    setState(() {
      _isEditing = true;
      _controller.text = widget.title ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _commit() {
    if (!_isEditing) return;
    final raw = _controller.text;
    widget.onChanged(raw);
    setState(() => _isEditing = false);
  }

  void _cancel() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
      _controller.text = widget.title ?? '';
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) _commit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLine = formatEntryDate(widget.date);
    final primaryText = widget.title ?? dateLine;

    if (_isEditing) {
      return _InlineTitleField(
        controller: _controller,
        focusNode: _focusNode,
        hintText: dateLine,
        onSubmitted: (_) => _commit(),
        onCancel: _cancel,
      );
    }

    return InkWell(
      onTap: widget.editable ? _startEditing : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              primaryText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.editable) ...[
            const SizedBox(width: 6),
            AppIcon(
              PhosphorIconsDuotone.pencilSimple,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineTitleField extends StatelessWidget {
  const _InlineTitleField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
