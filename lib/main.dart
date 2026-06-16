import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/audio_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/auth_service.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/layout_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/photo_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/quote_service.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/data/services/subscription_service.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/data/services/weather_service.dart';
import 'package:journaling_app_rewrite/hive/hive_registrar.g.dart';
import 'package:journaling_app_rewrite/routing/app_router.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auth is disabled in this build — Firebase has been removed for now.
  // The app is local-first, so a DisabledAuthService keeps the Profile
  // auth UI inert (sign-in buttons disabled, message shown).
  final AuthService authService = DisabledAuthService(
    'Sign-in is not available in this build.',
  );

  await Hive.initFlutter();
  Hive.registerAdapters();
  debugPrint('[main] Hive initialized, adapters registered');

  final entriesBox = await Hive.openBox<JournalEntry>('journalEntries_v6');
  final layoutsBox = await Hive.openBox<JournalLayout>('journalLayouts_v6');
  final settingsBox = await Hive.openBox<String>('settings');
  debugPrint(
    '[main] boxes opened: entries=${entriesBox.length}, layouts=${layoutsBox.length}, settings=${settingsBox.length}',
  );

  final entryStorage = HiveStorageService(entriesBox);
  final layoutStorage = LayoutStorageService(layoutsBox);
  final settingsStorage = SettingsStorageService(settingsBox);

  final layoutRepository = LayoutRepository(layoutStorage, settingsStorage);
  final blockSettings = BlockSettings(settingsStorage);
  final themeSettings = ThemeSettings(settingsStorage);
  final streakRewardSettings = StreakRewardSettings(settingsStorage);
  final journalRepository = JournalRepository(
    entryStorage,
    layoutRepository,
    blockSettings,
    themeSettings,
  );
  final debugSettings = DebugSettings(settingsStorage);
  final quoteService = QuoteService(settingsBox);
  final weatherService = WeatherService(settingsBox);
  final photoStorage = PhotoStorageService();
  final audioStorage = AudioStorageService();
  final authRepository = AuthRepository(authService);

  // RevenueCat must be configured before any other Purchases call.
  await SubscriptionService.configure();
  final subscriptionRepository = SubscriptionRepository(
    SubscriptionService(),
    settingsStorage,
  );
  await subscriptionRepository.init();

  await layoutRepository.seedDefaultIfEmpty();

  runApp(
    MyApp(
      authRepository: authRepository,
      journalRepository: journalRepository,
      layoutRepository: layoutRepository,
      debugSettings: debugSettings,
      themeSettings: themeSettings,
      blockSettings: blockSettings,
      streakRewardSettings: streakRewardSettings,
      quoteService: quoteService,
      weatherService: weatherService,
      photoStorage: photoStorage,
      audioStorage: audioStorage,
      subscriptionRepository: subscriptionRepository,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.authRepository,
    required this.journalRepository,
    required this.layoutRepository,
    required this.debugSettings,
    required this.themeSettings,
    required this.blockSettings,
    required this.streakRewardSettings,
    required this.quoteService,
    required this.weatherService,
    required this.photoStorage,
    required this.audioStorage,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final JournalRepository journalRepository;
  final LayoutRepository layoutRepository;
  final DebugSettings debugSettings;
  final ThemeSettings themeSettings;
  final BlockSettings blockSettings;
  final StreakRewardSettings streakRewardSettings;
  final QuoteService quoteService;
  final WeatherService weatherService;
  final PhotoStorageService photoStorage;
  final AudioStorageService audioStorage;
  final SubscriptionRepository subscriptionRepository;

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
    widget.authRepository.dispose();
    widget.subscriptionRepository.dispose();
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
      authRepository: widget.authRepository,
      journalRepository: widget.journalRepository,
      layoutRepository: widget.layoutRepository,
      debugSettings: widget.debugSettings,
      themeSettings: widget.themeSettings,
      blockSettings: widget.blockSettings,
      streakRewardSettings: widget.streakRewardSettings,
      quoteService: widget.quoteService,
      weatherService: widget.weatherService,
      photoStorage: widget.photoStorage,
      audioStorage: widget.audioStorage,
      subscriptionRepository: widget.subscriptionRepository,
      child: ListenableBuilder(
        listenable: widget.themeSettings,
        builder: (context, _) {
          // The selected palette bakes in its own brightness (GUS-27), so
          // a single `theme` drives the whole app — no light/dark swap.
          final palette = widget.themeSettings.palette;
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Journaling App',
            theme: buildAppTheme(palette),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
