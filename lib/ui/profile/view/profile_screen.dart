import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/streak_stat_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          _SectionHeader(label: 'Streak'),
          ListenableBuilder(
            listenable: deps.journalRepository,
            builder: (context, _) => StreakStatCard(
              streak: computeStreak(deps.journalRepository.getAllEntries()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const AppIcon(PhosphorIconsDuotone.gear),
            title: const Text('Settings'),
            subtitle: const Text('Appearance and debug options'),
            trailing: const AppIcon(PhosphorIconsDuotone.caretRight),
            onTap: () => context.push(Routes.settings),
          ),
          ListTile(
            leading: const AppIcon(PhosphorIconsDuotone.squaresFour),
            title: const Text('Layouts'),
            subtitle: const Text('Manage journal entry templates'),
            trailing: const AppIcon(PhosphorIconsDuotone.caretRight),
            onTap: () => context.push(Routes.layouts),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
