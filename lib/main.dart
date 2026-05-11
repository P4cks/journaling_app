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
import 'package:journaling_app_rewrite/hive/hive_registrar.g.dart';
import 'package:journaling_app_rewrite/routing/app_router.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();
  debugPrint('[main] Hive initialized, adapters registered');

  final entriesBox = await Hive.openBox<JournalEntry>('journalEntries_v4');
  final layoutsBox = await Hive.openBox<JournalLayout>('journalLayouts_v3');
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

  await layoutRepository.seedDefaultIfEmpty();

  runApp(
    MyApp(
      journalRepository: journalRepository,
      layoutRepository: layoutRepository,
      debugSettings: debugSettings,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.journalRepository,
    required this.layoutRepository,
    required this.debugSettings,
  });

  final JournalRepository journalRepository;
  final LayoutRepository layoutRepository;
  final DebugSettings debugSettings;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      journalRepository: journalRepository,
      layoutRepository: layoutRepository,
      debugSettings: debugSettings,
      child: MaterialApp.router(
        title: 'Journaling App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
