import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';

/// Text-block-global configuration: an optional character limit applied
/// to every text block in every entry. Leaving the field empty removes
/// the limit.
///
/// Controlled by the parent `BlockSettingsViewModel` — this widget
/// only binds the `textCharLimitController` and surfaces validation.
/// Saving happens screen-wide via `BlockSettingsScreen`'s leave prompt.
class TextBlockSettings extends StatelessWidget {
  const TextBlockSettings({super.key, required this.vm});

  final BlockSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Character limit',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Applied to every text block. Leave blank for no limit.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: vm.textCharLimitController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Limit',
            hintText: 'e.g. 200',
            border: const OutlineInputBorder(),
            errorText: vm.textCharLimitError,
          ),
        ),
      ],
    );
  }
}
