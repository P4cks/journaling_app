import 'package:flutter/material.dart';

/// Modal bottom sheet that lets the user pick a prompt for a prompt block.
///
/// Returns the chosen prompt string, or `null` if dismissed without picking.
/// The user can either tap an entry from [prompts] or use the
/// "Type custom prompt…" tile to type a one-off prompt (not saved to the
/// global list).
Future<String?> showPromptPickerSheet(
  BuildContext context, {
  required List<String> prompts,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PromptPickerBody(prompts: prompts, selected: selected),
    ),
  );
}

class _PromptPickerBody extends StatefulWidget {
  const _PromptPickerBody({required this.prompts, required this.selected});

  final List<String> prompts;
  final String? selected;

  @override
  State<_PromptPickerBody> createState() => _PromptPickerBodyState();
}

class _PromptPickerBodyState extends State<_PromptPickerBody> {
  bool _typing = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _typing = false),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.of(context).pop(text);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
