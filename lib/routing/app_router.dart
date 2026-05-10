import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_scaffold_shell.dart';
import 'package:journaling_app_rewrite/ui/home/view/home_screen.dart';
import 'package:journaling_app_rewrite/ui/journal_entries/view/journal_entries_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffoldShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profile,
              name: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              name: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.journalEntries,
              name: RouteNames.journalEntries,
              builder: (context, state) => const JournalEntriesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
