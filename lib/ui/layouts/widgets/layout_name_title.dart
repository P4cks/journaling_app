import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// AppBar title for the layout editor — mirrors the inline tap-to-edit
/// pattern used by [EditorTitle] on the journal-entry screen. Renders the
/// current layout name as a tappable text; tapping swaps in a `TextField`
/// bound to the same controller, so the parent ViewModel's listeners keep
/// firing as the user types.
class LayoutNameTitle extends StatefulWidget {
  const LayoutNameTitle({
    super.key,
    required this.controller,
    this.hintText = 'Layout name',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  State<LayoutNameTitle> createState() => _LayoutNameTitleState();
}

class _LayoutNameTitleState extends State<LayoutNameTitle> {
  bool _isEditing = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() => _isEditing = false);
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    if (_isEditing) {
      return TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: true,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _focusNode.unfocus(),
        style: titleStyle,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: titleStyle?.copyWith(
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final text = widget.controller.text;
        final isEmpty = text.isEmpty;
        return InkWell(
          onTap: _startEditing,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  isEmpty ? widget.hintText : text,
                  style: titleStyle?.copyWith(
                    color:
                        isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              AppIcon(
                PhosphorIconsDuotone.pencilSimple,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.55),
              ),
            ],
          ),
        );
      },
    );
  }
}
