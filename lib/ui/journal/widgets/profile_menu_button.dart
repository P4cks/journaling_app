import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Top-bar profile button. Opens a popup menu containing a streak
/// summary and auth-state-aware items: when signed out, a "Sign in"
/// row that pushes `/profile`; when signed in, the user's name/email
/// header plus a "Sign out" row guarded by a confirm dialog. Always
/// includes navigation rows for Settings, Layouts, Block settings.
/// Replaces the former Profile tab.
///
/// NOTE: Currently unused. The main journal screen now uses the
/// profile-free [AppMenuButton] (`app_menu_button.dart`). This component
/// is retained intentionally for when user profiles are reimplemented.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthRepository repository,
    AppUser user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          'You will be signed out of ${user.displayName ?? user.email ?? 'this account'}. '
          'Your local journal stays on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await repository.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final scheme = Theme.of(context).colorScheme;
    final authRepository = deps.authRepository;

    // Rebuild the menu icon when auth state changes so the dropdown
    // reflects the current sign-in state without requiring a manual
    // reopen.
    return ListenableBuilder(
      listenable: authRepository,
      builder: (context, _) {
        final user = authRepository.currentUser;
        final isSignedIn = user != null;
        final isConfigured = authRepository.isConfigured;
        final isPro = deps.subscriptionRepository.isPro;

        return PopupMenuButton<String>(
          tooltip: 'Profile',
          icon: AppIcon(
            isSignedIn
                ? HugeIcons.strokeRoundedUserCheck01
                : HugeIcons.strokeRoundedUserCircle,
            color: scheme.onSurface,
          ),
          position: PopupMenuPosition.under,
          onOpened: () => FocusManager.instance.primaryFocus?.unfocus(),
          onSelected: (value) async {
            FocusManager.instance.primaryFocus?.unfocus();
            switch (value) {
              case 'sign-in':
              case 'profile':
                await context.push(Routes.profile);
                break;
              case 'sign-out':
                if (user != null) {
                  await _confirmSignOut(context, authRepository, user);
                }
                break;
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
              enabled: false,
              padding: EdgeInsets.zero,
              child: _StreakHeader(repository: deps.journalRepository),
            ),
            if (isSignedIn)
              PopupMenuItem<String>(
                value: 'profile',
                padding: EdgeInsets.zero,
                child: _SignedInHeader(user: user),
              ),
            const PopupMenuDivider(),
            if (isSignedIn)
              PopupMenuItem<String>(
                value: 'sign-out',
                child: _MenuRow(
                  icon: HugeIcons.strokeRoundedLogout01,
                  label: 'Sign out',
                ),
              )
            else if (isConfigured)
              PopupMenuItem<String>(
                value: 'sign-in',
                child: _MenuRow(
                  icon: HugeIcons.strokeRoundedLogin01,
                  label: 'Sign in',
                ),
              ),
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
                label: 'Manage Layouts',
              ),
            ),
            PopupMenuItem<String>(
              value: 'block-settings',
              child: _MenuRow(
                icon: HugeIcons.strokeRoundedFilterHorizontal,
                label: 'Manage Blocks',
              ),
            ),
            if (isPro) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: _ProBanner(),
              ),
            ],
          ],
        );
      },
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

class _ProBanner extends StatelessWidget {
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

class _StreakHeader extends StatelessWidget {
  const _StreakHeader({required this.repository});

  final Listenable repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final deps = AppDependencies.of(context);
        final streak = computeStreak(deps.journalRepository.getAllEntries());
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              AppIcon(
                HugeIcons.strokeRoundedFire,
                size: 22,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak.current > 0
                          ? '${streak.current}-day streak'
                          : 'No active streak',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (streak.longest > 0)
                      Text(
                        'Longest: ${streak.longest} days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = user.displayName ?? user.email ?? 'Signed in';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          AppIcon(
            HugeIcons.strokeRoundedUserCheck01,
            size: 22,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          AppIcon(
            HugeIcons.strokeRoundedArrowRight01,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
