import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debug = AppDependencies.of(context).debugSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('Layouts'),
            subtitle: const Text('Manage journal entry templates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.layouts),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Debug',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListenableBuilder(
            listenable: debug,
            builder: (context, _) => SwitchListTile(
              secondary: const Icon(Icons.lock_open_outlined),
              title: const Text('Unlock all days'),
              subtitle: const Text(
                'Select and edit any past or future day',
              ),
              value: debug.unlockAllDays,
              onChanged: debug.setUnlockAllDays,
            ),
          ),
        ],
      ),
    );
  }
}
