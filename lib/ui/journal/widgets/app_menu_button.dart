import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Top-bar app menu. A hamburger button that opens a popup menu with
/// navigation rows for Settings, Manage Layout, and Manage Blocks.
///
/// This is the simplified, profile-free menu currently wired into the
/// main journal screen. The richer profile-/auth-aware variant lives in
/// `profile_menu_button.dart` (`ProfileMenuButton`) and is kept for when
/// user profiles are reimplemented.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: AppIcon(HugeIcons.strokeRoundedMenu01, color: scheme.onSurface),
      position: PopupMenuPosition.under,
      onOpened: () => FocusManager.instance.primaryFocus?.unfocus(),
      onSelected: (value) async {
        FocusManager.instance.primaryFocus?.unfocus();
        switch (value) {
          case 'settings':
            await context.push(Routes.settings);
            break;
          case 'layouts':
            await context.push(Routes.layouts);
            break;
          case 'block-settings':
            await context.push(Routes.blockSettings);
            break;
        }
        // Defend against focus auto-restoration when the previously-
        // focused TextField becomes visible again on pop.
        FocusManager.instance.primaryFocus?.unfocus();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settings',
          child: _MenuRow(
            icon: HugeIcons.strokeRoundedSettings01,
            label: 'Settings',
          ),
        ),
        PopupMenuItem<String>(
          value: 'layouts',
          child: _MenuRow(
            icon: HugeIcons.strokeRoundedDashboardSquareSetting,
            label: 'Manage Layout',
          ),
        ),
        PopupMenuItem<String>(
          value: 'block-settings',
          child: _MenuRow(
            icon: HugeIcons.strokeRoundedBlockGame,
            label: 'Manage Blocks',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final HugeIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
