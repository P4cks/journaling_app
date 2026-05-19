import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';

/// Prompt-block-global configuration. Two settings:
///
/// 1. A list of prompts entered as free text (one per line).
/// 2. A `Random Prompts` toggle:
///    - **on** (default) → `PromptStrategy.random`: deterministic per
///      date + slot, balanced across days so each prompt rotates
///      evenly. The prompt is baked into the entry at materialization.
///    - **off** → `PromptStrategy.manual`: the widget opens its picker
///      sheet on first build of each new entry so the user chooses.
///
/// Controlled by the parent `BlockSettingsViewModel` — this widget
/// only binds to the VM's `promptsController` / `promptStrategy`.
/// Saving happens screen-wide via `BlockSettingsScreen`'s leave prompt.
///
/// Editing here only affects entries created **after** the save —
/// each entry locks in its prompt at materialization time (or, in
/// manual mode, the first time the user opens its picker).
class PromptBlockSettings extends StatelessWidget {
  const PromptBlockSettings({super.key, required this.vm});

  final BlockSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRandom = vm.promptStrategy == PromptStrategy.random;
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
          controller: vm.promptsController,
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
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Random Prompts'),
          subtitle: Text(
            isRandom
                ? 'Chooses prompts automatically.'
                : 'You pick a prompt for each new entry. Long-press the block to change it.',
          ),
          value: isRandom,
          onChanged: (on) => vm.setPromptStrategy(
            on ? PromptStrategy.random : PromptStrategy.manual,
          ),
        ),
      ],
    );
  }
}
