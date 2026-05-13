class Routes {
  Routes._();

  static const home = '/';
  static const journalEntry = '/journal/:date';
  static const entries = '/entries';

  static const settings = '/settings';
  static const layouts = '/layouts';
  static const newLayout = '/layouts/new';
  static const editLayout = '/layouts/edit/:id';
  static const blockSettings = '/block-settings';
  static const textBlockSettings = '/block-settings/text';
  static const promptBlockSettings = '/block-settings/prompt';

  static String journalEntryFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '/journal/$y-$m-$d';
  }

  static String editLayoutFor(String id) => '/layouts/edit/$id';
}

class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const journalEntry = 'journalEntry';
  static const entries = 'entries';
  static const settings = 'settings';
  static const layouts = 'layouts';
  static const newLayout = 'newLayout';
  static const editLayout = 'editLayout';
  static const blockSettings = 'blockSettings';
  static const textBlockSettings = 'textBlockSettings';
  static const promptBlockSettings = 'promptBlockSettings';
}
