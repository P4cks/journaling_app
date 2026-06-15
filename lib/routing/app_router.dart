import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/journal/view/main_journal_screen.dart';
import 'package:journaling_app_rewrite/ui/journal_entries/view/journal_entries_screen.dart';
import 'package:journaling_app_rewrite/ui/statistics/view/statistics_screen.dart';
import 'package:journaling_app_rewrite/ui/layouts/view/layout_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/layouts/view/layouts_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/block_settings_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/custom_block_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/habit_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/profile_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/wannado_editor_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/settings_screen.dart';
import 'package:journaling_app_rewrite/ui/profile/view/theme_settings_screen.dart';
import 'package:journaling_app_rewrite/ui/subscription/view/subscription_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Flat top-level router. The bottom-nav shell is gone; every screen
/// is reachable directly from the main journal screen via top-bar
/// actions or push-and-pop.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      name: RouteNames.home,
      builder: (context, state) => const MainJournalScreen(),
    ),
    GoRoute(
      path: Routes.journalEntry,
      name: RouteNames.journalEntry,
      builder: (context, state) {
        final iso = state.pathParameters['date']!;
        final date = DateTime.parse(iso);
        return MainJournalScreen(initialDate: date);
      },
    ),
    GoRoute(
      path: Routes.entries,
      name: RouteNames.entries,
      builder: (context, state) => const JournalEntriesScreen(),
    ),
    GoRoute(
      path: Routes.statistics,
      name: RouteNames.statistics,
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.themeSettings,
      name: RouteNames.themeSettings,
      builder: (context, state) => const ThemeSettingsScreen(),
    ),
    GoRoute(
      path: Routes.profile,
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: Routes.subscription,
      name: RouteNames.subscription,
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: Routes.layouts,
      name: RouteNames.layouts,
      builder: (context, state) => const LayoutsScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: RouteNames.newLayout,
          builder: (context, state) {
            final raw =
                state.uri.queryParameters[Routes.newLayoutKindQueryParam];
            final kind = LayoutKind.values.firstWhere(
              (k) => k.name == raw,
              orElse: () => LayoutKind.blockOnly,
            );
            return LayoutEditorScreen(layoutId: null, initialKind: kind);
          },
        ),
        GoRoute(
          path: 'edit/:id',
          name: RouteNames.editLayout,
          builder: (context, state) =>
              LayoutEditorScreen(layoutId: state.pathParameters['id']),
        ),
      ],
    ),
    GoRoute(
      path: Routes.blockSettings,
      name: RouteNames.blockSettings,
      builder: (context, state) => const BlockSettingsScreen(),
    ),
    GoRoute(
      path: Routes.newCustomBlock,
      name: RouteNames.newCustomBlock,
      builder: (context, state) => const CustomBlockEditorScreen(),
    ),
    GoRoute(
      path: Routes.editCustomBlock,
      name: RouteNames.editCustomBlock,
      builder: (context, state) =>
          CustomBlockEditorScreen(definitionId: state.pathParameters['id']),
    ),
    GoRoute(
      path: Routes.newHabitBlock,
      name: RouteNames.newHabitBlock,
      builder: (context, state) => const HabitEditorScreen(),
    ),
    GoRoute(
      path: Routes.editHabitBlock,
      name: RouteNames.editHabitBlock,
      builder: (context, state) =>
          HabitEditorScreen(definitionId: state.pathParameters['id']),
    ),
    GoRoute(
      path: Routes.newWannado,
      name: RouteNames.newWannado,
      builder: (context, state) => const WannadoEditorScreen(),
    ),
    GoRoute(
      path: Routes.editWannado,
      name: RouteNames.editWannado,
      builder: (context, state) =>
          WannadoEditorScreen(definitionId: state.pathParameters['id']),
    ),
  ],
);
