import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Icon + title + caret-right `ListTile` that pushes [route].
///
/// Used for navigation rows inside `SettingsSection`s (Settings →
/// Manage templates / Configure blocks, etc.) where the only thing
/// each row does is route to another screen via `context.push`.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
  });

  final HugeIconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(icon),
      title: Text(title),
      trailing: AppIcon(HugeIcons.strokeRoundedArrowRight01),
      onTap: () => context.push(route),
    );
  }
}
