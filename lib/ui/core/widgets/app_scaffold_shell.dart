import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _onDestinationTap(BuildContext context, int index) async {
    // Ask any registered unsaved-state guard (e.g. layout editor with dirty
    // state) whether we may leave before switching branches. PopScope only
    // catches pops; tab switches don't go through it, so the guard fills
    // the gap.
    final guard = AppDependencies.of(context).navigationGuard;
    final allowed = await guard.canLeave();
    if (!allowed) return;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onDestinationTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: AppIcon(PhosphorIconsDuotone.userCircle),
            activeIcon: AppIcon(PhosphorIconsFill.userCircle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: AppIcon(PhosphorIconsDuotone.house),
            activeIcon: AppIcon(PhosphorIconsFill.house),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: AppIcon(PhosphorIconsDuotone.bookOpen),
            activeIcon: AppIcon(PhosphorIconsFill.bookOpen),
            label: 'Entries',
          ),
        ],
      ),
    );
  }
}
