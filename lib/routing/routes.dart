import 'package:journaling_app_rewrite/data/model/layout_kind.dart';

class Routes {
  Routes._();

  static const home = '/';
  static const journalEntry = '/journal/:date';
  static const entries = '/entries';
  static const statistics = '/statistics';

  static const settings = '/settings';
  static const profile = '/profile';
  static const layouts = '/layouts';
  static const newLayout = '/layouts/new';
  static const editLayout = '/layouts/edit/:id';
  static const blockSettings = '/block-settings';
  static const newCustomBlock = '/custom-block/new';
  static const editCustomBlock = '/custom-block/edit/:id';
  static const subscription = '/subscription';

  /// Query-parameter name on `/layouts/new` carrying the chosen
  /// [LayoutKind]'s `name`. Reads as `null` when absent; the editor
  /// falls back to [LayoutKind.blockOnly] in that case.
  static const newLayoutKindQueryParam = 'kind';

  static String journalEntryFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '/journal/$y-$m-$d';
  }

  static String editLayoutFor(String id) => '/layouts/edit/$id';

  static String editCustomBlockFor(String id) => '/custom-block/edit/$id';

  static String newLayoutFor(LayoutKind kind) =>
      '$newLayout?$newLayoutKindQueryParam=${kind.name}';
}

class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const journalEntry = 'journalEntry';
  static const entries = 'entries';
  static const statistics = 'statistics';
  static const settings = 'settings';
  static const profile = 'profile';
  static const layouts = 'layouts';
  static const newLayout = 'newLayout';
  static const editLayout = 'editLayout';
  static const blockSettings = 'blockSettings';
  static const newCustomBlock = 'newCustomBlock';
  static const editCustomBlock = 'editCustomBlock';
  static const subscription = 'subscription';
}
