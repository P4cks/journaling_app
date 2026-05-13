// Shared date-formatting helpers used across the home, editor, and
// entries-list surfaces. Kept dependency-free (no `intl`) — the formats
// are simple and the app is English-only for now.

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// e.g. "May 11, 2026".
String formatEntryDate(DateTime d) =>
    '${_monthsShort[d.month - 1]} ${d.day}, ${d.year}';

/// e.g. "May 2026". Used as the section header on the entries list.
String formatMonthHeader(int year, int month) =>
    '${_monthsLong[month - 1]} $year';
