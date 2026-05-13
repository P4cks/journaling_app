import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Top-bar profile button. Opens a popup menu containing a streak +
/// auth-status header and items for Settings, Layouts, and Block
/// settings. Replaces the former Profile tab.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Profile',
      icon: AppIcon(PhosphorIconsDuotone.userCircle, color: scheme.onSurface),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.push(Routes.settings);
            break;
          case 'layouts':
            context.push(Routes.layouts);
            break;
          case 'block-settings':
            context.push(Routes.blockSettings);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _StreakHeader(repository: deps.journalRepository),
        ),
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _AuthHeader(repository: deps.authRepository),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'settings',
          child: _MenuRow(icon: PhosphorIconsDuotone.gear, label: 'Settings'),
        ),
        const PopupMenuItem<String>(
          value: 'layouts',
          child: _MenuRow(
            icon: PhosphorIconsDuotone.squaresFour,
            label: 'Layouts',
          ),
        ),
        const PopupMenuItem<String>(
          value: 'block-settings',
          child: _MenuRow(
            icon: PhosphorIconsDuotone.slidersHorizontal,
            label: 'Block settings',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
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
                PhosphorIconsDuotone.flame,
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

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.repository});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final user = repository.currentUser;
        final label = user == null
            ? (repository.isConfigured ? 'Not signed in' : 'Auth disabled')
            : (user.displayName ?? user.email ?? 'Signed in');
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              AppIcon(
                user == null
                    ? PhosphorIconsDuotone.userCircle
                    : PhosphorIconsDuotone.userCircleCheck,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
