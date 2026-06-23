import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
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
    final subscriptionRepository =
        AppDependencies.of(context).subscriptionRepository;

    // Rebuild the menu when entitlement state changes so the Pro badge
    // appears/disappears without requiring a manual reopen.
    return ListenableBuilder(
      listenable: subscriptionRepository,
      builder: (context, _) {
        final isPro = subscriptionRepository.isPro;

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
            if (isPro) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: _ProBadge(),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Small "Pro active" badge shown at the bottom of the app menu when the
/// `pro` entitlement is live. Mirrors the banner in `ProfileMenuButton`.
class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppIcon(
            HugeIcons.strokeRoundedCrown,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Journaling App Pro',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
