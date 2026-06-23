import 'package:flutter/material.dart';

import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';

/// Modal bottom sheet that lets the user pick a prompt for a prompt block.
///
/// Returns the chosen prompt string, or `null` if dismissed without picking.
/// The user can either tap an entry from [prompts] or use the
/// "Type custom prompt…" tile to type a one-off prompt.
///
/// When [onSaveToRotation] is supplied, the type-a-prompt body shows an
/// "Add to my prompts" checkbox. Ticking it and tapping Done first awaits
/// [onSaveToRotation] (which appends the prompt to the global list) and
/// then returns the prompt as the picked value. The callback owns
/// de-duplication; the sheet suppresses the checkbox when the typed text
/// already matches an existing prompt.
Future<String?> showPromptPickerSheet(
  BuildContext context, {
  required List<String> prompts,
  String? selected,
  Future<void> Function(String prompt)? onSaveToRotation,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PromptPickerBody(
        prompts: prompts,
        selected: selected,
        onSaveToRotation: onSaveToRotation,
      ),
    ),
  );
}

class _PromptPickerBody extends StatefulWidget {
  const _PromptPickerBody({
    required this.prompts,
    required this.selected,
    required this.onSaveToRotation,
  });

  final List<String> prompts;
  final String? selected;
  final Future<void> Function(String prompt)? onSaveToRotation;

  @override
  State<_PromptPickerBody> createState() => _PromptPickerBodyState();
}

class _PromptPickerBodyState extends State<_PromptPickerBody> {
  bool _typing = false;
  bool _saveToRotation = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild as the user types so the "Add to my prompts" checkbox can
    // disable itself once the text already matches an existing prompt.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitTyped() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final save = widget.onSaveToRotation;
    if (_saveToRotation && save != null && !widget.prompts.contains(text)) {
      await save(text);
    }
    if (!mounted) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _typing ? 'Type a prompt' : 'Pick a prompt',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          if (_typing) _buildTypeBody(theme) else _buildListBody(theme),
        ],
      ),
    );
  }

  Widget _buildListBody(ThemeData theme) {
    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (final p in widget.prompts)
            ListTile(
              title: Text(p),
              selected: p == widget.selected,
              selectedTileColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.4,
              ),
              onTap: () => Navigator.of(context).pop(p),
            ),
          ListTile(
            leading: Icon(Icons.edit, color: theme.colorScheme.primary),
            title: Text(
              'Type custom prompt…',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onTap: () => setState(() => _typing = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBody(ThemeData theme) {
    final trimmed = _controller.text.trim();
    final alreadySaved = widget.prompts.contains(trimmed);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What do you want to write about?',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.onSaveToRotation != null) ...[
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Add to my prompts'),
              subtitle: alreadySaved
                  ? const Text('Already in your prompts')
                  : null,
              // Once the text matches an existing prompt there is nothing
              // to save, so lock the checkbox off.
              value: _saveToRotation && !alreadySaved,
              onChanged: alreadySaved
                  ? null
                  : (on) => setState(() => _saveToRotation = on ?? false),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                variant: AppButtonVariant.text,
                onPressed: () => setState(() => _typing = false),
                label: 'Back',
              ),
              const SizedBox(width: 8),
              AppButton(
                variant: AppButtonVariant.primary,
                onPressed: _submitTyped,
                label: 'Done',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
