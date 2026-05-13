import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/settings_section.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/text_block_settings.dart';

/// Index screen for block-type-global configuration. Lists every block
/// type that has user-configurable settings and pushes into its dedicated
/// screen on tap. Block types with no settings simply do not appear.
class BlockSettingsScreen extends StatelessWidget {
  const BlockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <SettingsSection>[
      SettingsSection(label: "Text Block", widget: [TextBlockSettings()]),
      SettingsSection(label: "Prompt Block", widget: [PromptBlockSettings()]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Block settings')),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          return entries[i];
        },
      ),
    );
  }
}

