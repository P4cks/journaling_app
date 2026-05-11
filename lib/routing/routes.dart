class Routes {
  Routes._();

  static const home = '/';
  static const profile = '/profile';
  static const journalEntries = '/journal-entries';
  static const journalEntry = '/journal/:date';

  static const layouts = '/profile/layouts';
  static const newLayout = '/profile/layouts/new';
  static const editLayout = '/profile/layouts/edit/:id';

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
  static const layouts = 'layouts';
  static const newLayout = 'newLayout';
  static const editLayout = 'editLayout';
}
