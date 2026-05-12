import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Index screen for block-type-global configuration. Lists every block
/// type that has user-configurable settings and pushes into its dedicated
/// screen on tap. Block types with no settings simply do not appear.
class BlockSettingsScreen extends StatelessWidget {
  const BlockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_BlockSettingsEntry>[
      _BlockSettingsEntry(
        type: BlockType.textBlock,
        subtitle: 'Optional character limit',
        route: Routes.textBlockSettings,
      ),
      _BlockSettingsEntry(
        type: BlockType.promptBlock,
        subtitle: 'Prompt list and rotation strategy',
        route: Routes.promptBlockSettings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Block settings')),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return ListTile(
            leading: AppIcon(entry.type.icon),
            title: Text(entry.type.label),
            subtitle: Text(entry.subtitle),
            trailing: const AppIcon(PhosphorIconsDuotone.caretRight),
            onTap: () => context.push(entry.route),
          );
        },
      ),
    );
  }
}

class _BlockSettingsEntry {
  const _BlockSettingsEntry({
    required this.type,
    required this.subtitle,
    required this.route,
  });

  final BlockType type;
  final String subtitle;
  final String route;
}
