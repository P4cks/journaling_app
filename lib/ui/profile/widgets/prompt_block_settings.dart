import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';

/// Prompt-block-global configuration. Two settings:
///
/// 1. A list of prompts entered as free text (one per line).
/// 2. A strategy: `daily` (deterministic per date + slot, balanced
///    across days so each prompt rotates evenly), `random`
///    (independent random pick per slot at entry materialization), or
///    `manual` (user picks per entry).
///
/// Controlled by the parent `BlockSettingsViewModel` — this widget
/// only binds to the VM's `promptsController` / `promptStrategy`.
/// Saving happens screen-wide via `BlockSettingsScreen`'s leave prompt.
///
/// Editing here only affects entries created **after** the save —
/// each entry locks in its prompt at materialization time.
class PromptBlockSettings extends StatelessWidget {
  const PromptBlockSettings({super.key, required this.vm});

  final BlockSettingsViewModel vm;

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
            ButtonSegment(value: PromptStrategy.manual, label: Text('Manual')),
          ],
          selected: {vm.promptStrategy},
          onSelectionChanged: (selection) =>
              vm.setPromptStrategy(selection.first),
        ),
        const SizedBox(height: 6),
        Text(
          switch (vm.promptStrategy) {
            PromptStrategy.daily =>
              'Each day rotates through the list. Multiple prompt blocks on the same day get different prompts.',
            PromptStrategy.random =>
              'Each prompt block picks a random prompt independently.',
            PromptStrategy.manual =>
              'You pick a prompt for each new entry. Long-press the block to change it.',
          },
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
