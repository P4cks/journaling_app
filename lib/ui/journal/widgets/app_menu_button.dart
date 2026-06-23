import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

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
              case 'upgrade':
                // Free → present the paywall via the centralized gate
                // (handles offline + post-purchase state) (GUS-89).
                await requirePro(subscriptionRepository, context: context);
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
            const PopupMenuDivider(),
            // Pro state lives at the foot of the menu: a quiet "Pro active"
            // badge when subscribed, or a tappable "Free version → Upgrade"
            // badge that opens the paywall when not (GUS-89).
            if (isPro)
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: const _ProBadge(),
              )
            else
              PopupMenuItem<String>(
                value: 'upgrade',
                padding: EdgeInsets.zero,
                child: const _UpgradeBadge(),
              ),
          ],
        );
      },
    );
  }
}

/// Quiet single-line "Pro active" badge at the foot of the app menu when
/// the `pro` entitlement is live (GUS-89 — slimmed from the old two-line
/// banner so an active subscription is acknowledged, not advertised).
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            HugeIcons.strokeRoundedCrown,
            size: 15,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Pro active',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable "Free version → Upgrade to Pro" badge at the foot of the app
/// menu for free users (GUS-89). Selecting it routes through `requirePro`
/// (the centralized paywall gate) via the menu's `onSelected('upgrade')`.
/// Accent crown + chevron read it as an invitation, not a status row.
class _UpgradeBadge extends StatelessWidget {
  const _UpgradeBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          AppIcon(
            HugeIcons.strokeRoundedCrown,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free version',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Upgrade to Pro',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppIcon(
            HugeIcons.strokeRoundedArrowRight01,
            size: 16,
            color: scheme.primary,
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
