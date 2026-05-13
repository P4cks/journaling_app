import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Prompt-block-global configuration. Two settings:
///
/// 1. A list of prompts entered as free text (one per line).
/// 2. A strategy: `daily` (deterministic per date + slot, balanced
///    across days so each prompt rotates evenly) or `random`
///    (independent random pick per slot at entry materialization).
///
/// Editing here only affects entries created **after** the edit — each
/// entry locks in its prompt at materialization time so re-opening it
/// never re-rolls.
class PromptBlockSettings extends StatefulWidget {
  const PromptBlockSettings({super.key});

  @override
  State<PromptBlockSettings> createState() => _PromptBlockSettingsState();
}

class _PromptBlockSettingsState extends State<PromptBlockSettings> {
  final TextEditingController _controller = TextEditingController();
  bool _initialized = false;
  PromptStrategy _strategy = PromptStrategy.daily;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = AppDependencies.of(context).blockSettings;
    _controller.text = settings.prompts.join('\n');
    _strategy = settings.promptStrategy;
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parsePrompts() {
    return [
      for (final line in _controller.text.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }

  Future<void> _save() async {
    final settings = AppDependencies.of(context).blockSettings;
    final prompts = _parsePrompts();
    await settings.setPrompts(prompts);
    await settings.setPromptStrategy(_strategy);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          prompts.isEmpty
              ? 'Saved (no prompts configured)'
              : 'Saved ${prompts.length} prompt${prompts.length == 1 ? '' : 's'}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompts',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'One prompt per line. Empty lines are ignored.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 12,
          minLines: 6,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText:
                'What surprised you today?\nWhat are you grateful for?\nOne thing you learned…',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pick strategy',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<PromptStrategy>(
          segments: const [
            ButtonSegment(
              value: PromptStrategy.daily,
              label: Text('One per day'),
            ),
            ButtonSegment(value: PromptStrategy.random, label: Text('Random')),
          ],
          selected: {_strategy},
          onSelectionChanged: (selection) {
            setState(() => _strategy = selection.first);
          },
        ),
        const SizedBox(height: 6),
        Text(
          _strategy == PromptStrategy.daily
              ? 'Each day rotates through the list. Multiple prompt blocks on the same day get different prompts.'
              : 'Each prompt block picks a random prompt independently.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],

    );
  }
}
