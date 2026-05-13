import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/profile_auth_card.dart';
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
          SectionHeader(label: 'Profile'),
          ListenableBuilder(
            listenable: deps.authRepository,
            builder: (context, _) =>
                ProfileAuthCard(authRepository: deps.authRepository),
          ),
          const Divider(),
          ListTile(
            leading: const AppIcon(PhosphorIconsDuotone.gear),
            title: const Text('Preferences'),
            trailing: const AppIcon(PhosphorIconsDuotone.caretRight),
            onTap: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }
}
