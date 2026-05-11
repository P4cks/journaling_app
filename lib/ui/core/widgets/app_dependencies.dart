import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.journalRepository,
    required this.layoutRepository,
    required this.debugSettings,
    required super.child,
  });

  final JournalRepository journalRepository;
  final LayoutRepository layoutRepository;
  final DebugSettings debugSettings;

  static AppDependencies of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(widget != null, 'No AppDependencies found in context');
    return widget!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) =>
      journalRepository != oldWidget.journalRepository ||
      layoutRepository != oldWidget.layoutRepository ||
      debugSettings != oldWidget.debugSettings;
}
