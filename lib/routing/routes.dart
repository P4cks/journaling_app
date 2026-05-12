class Routes {
  Routes._();

  static const home = '/';
  static const profile = '/profile';
  static const journalEntries = '/journal-entries';
  static const journalEntry = '/journal/:date';

  static const settings = '/profile/settings';
  static const layouts = '/profile/layouts';
  static const newLayout = '/profile/layouts/new';
  static const editLayout = '/profile/layouts/edit/:id';
  static const blockSettings = '/profile/block-settings';
  static const textBlockSettings = '/profile/block-settings/text';
  static const promptBlockSettings = '/profile/block-settings/prompt';

  static String journalEntryFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '/journal/$y-$m-$d';
  }

  static String editLayoutFor(String id) => '/profile/layouts/edit/$id';
}

class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const profile = 'profile';
  static const journalEntries = 'journalEntries';
  static const journalEntry = 'journalEntry';
  static const settings = 'settings';
  static const layouts = 'layouts';
  static const newLayout = 'newLayout';
  static const editLayout = 'editLayout';
  static const blockSettings = 'blockSettings';
  static const textBlockSettings = 'textBlockSettings';
  static const promptBlockSettings = 'promptBlockSettings';
}
