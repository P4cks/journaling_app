import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/profile_auth_card.dart';

/// Standalone Profile screen pushed from the journal AppBar's profile
/// dropdown. Hosts the existing [ProfileAuthCard], which renders the
/// signed-out (Email / Google / Apple action buttons + bottom-sheet
/// email flow) or signed-in (avatar + name/email + provider + sign-out)
/// state for the current [AuthRepository.currentUser]. The
/// `ListenableBuilder` wrap means the body swaps the moment auth
/// completes without any extra navigation.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AppDependencies.of(context).authRepository;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: authRepository,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ProfileAuthCard(authRepository: authRepository),
        ),
      ),
    );
  }
}
