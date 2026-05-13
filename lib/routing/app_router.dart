import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_scaffold_shell.dart';
import 'package:journaling_app_rewrite/ui/home/view/home_screen.dart';
import 'package:journaling_app_rewrite/ui/journal_entries/view/journal_entries_screen.dart';
import 'package:journaling_app_rewrite/ui/journal_entry/view/journal_entry_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/layouts/view/layout_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/layouts/view/layouts_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/block_settings_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/profile_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/view/settings_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/text_block_settings.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
              routes: [
                GoRoute(
                  path: 'settings',
                  name: RouteNames.settings,
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'layouts',
                  name: RouteNames.layouts,
                  builder: (context, state) => const LayoutsScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: RouteNames.newLayout,
                      builder: (context, state) =>
                          const LayoutEditorScreen(layoutId: null),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      name: RouteNames.editLayout,
                      builder: (context, state) => LayoutEditorScreen(
                        layoutId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'block-settings',
                  name: RouteNames.blockSettings,
                  builder: (context, state) => const BlockSettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'text',
                      name: RouteNames.textBlockSettings,
                      builder: (context, state) => const TextBlockSettings(),
                    ),
                    GoRoute(
                      path: 'prompt',
                      name: RouteNames.promptBlockSettings,
                      builder: (context, state) => const PromptBlockSettings(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [

            GoRoute(
              path: Routes.home,
              name: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'journal/:date',
                  name: RouteNames.journalEntry,
                  builder: (context, state) {
                    final iso = state.pathParameters['date']!;
                    final date = DateTime.parse(iso);
                    return JournalEntryEditorScreen(date: date);
                  },
                ),
              ]
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
