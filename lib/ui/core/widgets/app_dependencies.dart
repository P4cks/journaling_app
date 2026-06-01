import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';
import 'package:journaling_app_rewrite/data/services/photo_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/quote_service.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/data/services/weather_service.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.authRepository,
    required this.journalRepository,
    required this.layoutRepository,
    required this.debugSettings,
    required this.themeSettings,
    required this.blockSettings,
    required this.quoteService,
    required this.weatherService,
    required this.photoStorage,
    required this.subscriptionRepository,
    required super.child,
  });

  final AuthRepository authRepository;
  final JournalRepository journalRepository;
  final LayoutRepository layoutRepository;
  final DebugSettings debugSettings;
  final ThemeSettings themeSettings;
  final BlockSettings blockSettings;
  final QuoteService quoteService;
  final WeatherService weatherService;
  final PhotoStorageService photoStorage;
  final SubscriptionRepository subscriptionRepository;

  static AppDependencies of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(widget != null, 'No AppDependencies found in context');
    return widget!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) =>
      authRepository != oldWidget.authRepository ||
      journalRepository != oldWidget.journalRepository ||
      layoutRepository != oldWidget.layoutRepository ||
      debugSettings != oldWidget.debugSettings ||
      themeSettings != oldWidget.themeSettings ||
      blockSettings != oldWidget.blockSettings ||
      quoteService != oldWidget.quoteService ||
      weatherService != oldWidget.weatherService ||
      photoStorage != oldWidget.photoStorage ||
      subscriptionRepository != oldWidget.subscriptionRepository;
}
