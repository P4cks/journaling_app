import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/layout_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/hive/hive_registrar.g.dart';
import 'package:journaling_app_rewrite/routing/app_router.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/navigation_guard.dart';
import 'package:journaling_app_rewrite/ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();
  debugPrint('[main] Hive initialized, adapters registered');

  final entriesBox = await Hive.openBox<JournalEntry>('journalEntries_v5');
  final layoutsBox = await Hive.openBox<JournalLayout>('journalLayouts_v4');
  final settingsBox = await Hive.openBox<String>('settings');
  debugPrint(
    '[main] boxes opened: entries=${entriesBox.length}, layouts=${layoutsBox.length}, settings=${settingsBox.length}',
  );

  final entryStorage = HiveStorageService(entriesBox);
  final layoutStorage = LayoutStorageService(layoutsBox);
  final settingsStorage = SettingsStorageService(settingsBox);

  final layoutRepository = LayoutRepository(layoutStorage, settingsStorage);
  final journalRepository = JournalRepository(entryStorage, layoutRepository);
  final debugSettings = DebugSettings(settingsStorage);
  final themeSettings = ThemeSettings(settingsStorage);
  final navigationGuard = NavigationGuard();

  await layoutRepository.seedDefaultIfEmpty();

  runApp(
    MyApp(
      journalRepository: journalRepository,
      layoutRepository: layoutRepository,
      debugSettings: debugSettings,
      themeSettings: themeSettings,
      navigationGuard: navigationGuard,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.journalRepository,
    required this.layoutRepository,
    required this.debugSettings,
    required this.themeSettings,
    required this.navigationGuard,
  });

  final JournalRepository journalRepository;
  final LayoutRepository layoutRepository;
  final DebugSettings debugSettings;
  final ThemeSettings themeSettings;
  final NavigationGuard navigationGuard;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold-start sweep — catches past-day entries left empty from a
    // previous session.
    widget.journalRepository.sweepEmptyPastEntries();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Catches the "user opened editor at 23:55, walked away, day rolled
      // over while app was backgrounded" case.
      widget.journalRepository.sweepEmptyPastEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      journalRepository: widget.journalRepository,
      layoutRepository: widget.layoutRepository,
      debugSettings: widget.debugSettings,
      themeSettings: widget.themeSettings,
      navigationGuard: widget.navigationGuard,
      child: ListenableBuilder(
        listenable: widget.themeSettings,
        builder: (context, _) {
          final palette = widget.themeSettings.palette;
          final secondary = widget.themeSettings.secondaryOverride;
          final accent = widget.themeSettings.accentOverride;
          final surfaceOverride = widget.themeSettings.debugSurfaceOverride;
          return MaterialApp.router(
            title: 'Journaling App',
            themeMode: widget.themeSettings.themeMode,
            theme: buildAppTheme(
              palette: palette,
              brightness: Brightness.light,
              secondary: secondary,
              accent: accent,
              surfaceOverride: surfaceOverride,
            ),
            darkTheme: buildAppTheme(
              palette: palette,
              brightness: Brightness.dark,
              secondary: secondary,
              accent: accent,
              surfaceOverride: surfaceOverride,
            ),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
