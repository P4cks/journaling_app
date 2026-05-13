import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_emptiness.dart';

/// Snapshot of a user's journaling streaks.
class StreakResult {
  const StreakResult({
    required this.current,
    required this.longest,
    this.anchorDate,
  });

  /// Days in the most-recent unbroken run that includes today or yesterday.
  /// Zero when the user has no entry on today nor yesterday.
  final int current;

  /// The longest run of consecutive non-empty entries in the user's history.
  final int longest;

  /// The most-recent day counted in the current streak (today or earlier).
  /// `null` when [current] is zero.
  final DateTime? anchorDate;

  static const empty = StreakResult(current: 0, longest: 0);
}

/// Pure function: compute the user's current and longest streaks from
/// [entries]. Only non-empty entries (see `JournalEntry.hasNoContent`)
/// participate in the count.
///
/// DST-safe — all date math is calendar-day arithmetic
/// (`DateTime(y, m, d)` + `subtract(Duration(days: 1))` re-normalized),
/// never timestamp differences. Across a US "fall back" night a single
/// day is 25 hours; across "spring forward" it's 23. Both still count
/// as one calendar day, which is what the user expects from a streak.
///
/// Pass [now] in tests; defaults to `DateTime.now()`.
StreakResult computeStreak(List<JournalEntry> entries, {DateTime? now}) {
  final days = <DateTime>{};
  for (final entry in entries) {
    if (entry.hasNoContent) continue;
    days.add(_normalize(entry.date));
  }
  if (days.isEmpty) return StreakResult.empty;

  final today = _normalize(now ?? DateTime.now());
  final yesterday = _addDays(today, -1);

  DateTime? anchor;
  if (days.contains(today)) {
    anchor = today;
  } else if (days.contains(yesterday)) {
    anchor = yesterday;
  }

  var current = 0;
  if (anchor != null) {
    var cursor = anchor;
    while (days.contains(cursor)) {
      current++;
      cursor = _addDays(cursor, -1);
    }
  }

  // Longest run: scan sorted-ascending dates once.
  final sorted = days.toList()..sort();
  var longest = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    if (_addDays(prev, 1) == cur) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 1;
    }
  }
  // current may exceed the scanned longest if the streak ends at today
  // and is the longest run — both walks cover that, but be defensive.
  if (current > longest) longest = current;

  return StreakResult(
    current: current,
    longest: longest,
    anchorDate: current > 0 ? anchor : null,
  );
}

/// Local-midnight normalization. Required so `==` and `Set.contains`
/// work as identity-on-day rather than identity-on-instant.
DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

/// Add (or subtract, with a negative argument) calendar days. Dart's
/// `DateTime` constructor normalizes overflow correctly across month and
/// year boundaries, leap years, and DST transitions.
DateTime _addDays(DateTime d, int delta) =>
    DateTime(d.year, d.month, d.day + delta);
