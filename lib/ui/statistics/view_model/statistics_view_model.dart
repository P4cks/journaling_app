import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/repositories/journal_repository.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';

/// Time-range selector for the statistics page.
enum StatRange { week, month, year, all }

extension StatRangeDisplay on StatRange {
  String get label => switch (this) {
    StatRange.week => 'Week',
    StatRange.month => 'Month',
    StatRange.year => 'Year',
    StatRange.all => 'All',
  };
}

/// One day's mood point on the time-series chart. `score` is null on
/// days with no mood entry — the line chart draws a gap, not a zero.
class MoodPoint {
  const MoodPoint({required this.day, required this.score});

  final DateTime day;
  final double? score;
}

/// One ISO-week bucket on the entry-frequency chart.
class WeekBucket {
  const WeekBucket({required this.weekStart, required this.count});

  /// Monday of the week (local midnight).
  final DateTime weekStart;
  final int count;
}

/// View-model for the statistics page. Subscribes to
/// `JournalRepository` and recomputes aggregates on every change.
class StatisticsViewModel extends ChangeNotifier {
  StatisticsViewModel({required JournalRepository repository})
    : _repository = repository {
    _repository.addListener(_onRepositoryChanged);
    _recompute();
  }

  final JournalRepository _repository;

  StatRange _range = StatRange.month;
  StatRange get range => _range;

  void setRange(StatRange value) {
    if (value == _range) return;
    _range = value;
    _recompute();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Computed aggregates (cached after _recompute)
  // ---------------------------------------------------------------------------

  int _totalEntries = 0;
  int get totalEntries => _totalEntries;

  int _totalWords = 0;
  int get totalWords => _totalWords;

  int _totalMoodEntries = 0;
  int get totalMoodEntries => _totalMoodEntries;

  StreakResult _streak = StreakResult.empty;
  StreakResult get streak => _streak;

  Map<String, int> _moodDistribution = const {};
  Map<String, int> get moodDistribution => _moodDistribution;

  List<MoodPoint> _moodOverTime = const [];
  List<MoodPoint> get moodOverTime => _moodOverTime;

  List<WeekBucket> _entryFrequency = const [];
  List<WeekBucket> get entryFrequency => _entryFrequency;

  bool get isEmpty => _totalEntries == 0;

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _onRepositoryChanged() {
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    final all = _repository.getAllEntries();
    // Streak is range-independent — it's a "lifetime" stat.
    _streak = computeStreak(all);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final window = _windowFor(_range, today, all);

    final inRange = <JournalEntry>[];
    for (final entry in all) {
      final d = _normalize(entry.date);
      if (window == null ||
          (!d.isBefore(window.start) && !d.isAfter(window.end))) {
        inRange.add(entry);
      }
    }

    _totalEntries = inRange.length;
    _totalWords = inRange.fold(0, (sum, e) => sum + _wordCountFor(e));
    _totalMoodEntries = inRange.where((e) => _firstMoodEmoji(e) != null).length;

    _moodDistribution = _computeMoodDistribution(inRange);
    _moodOverTime = window == null
        ? _computeMoodOverTimeUnbounded(inRange)
        : _computeMoodOverTime(inRange, window);
    _entryFrequency = window == null
        ? _computeEntryFrequencyUnbounded(inRange)
        : _computeEntryFrequency(inRange, window);
  }

  /// Returns the inclusive [start, end] window for [r], or `null` for
  /// `StatRange.all` (caller treats null as "no filter").
  _DateWindow? _windowFor(StatRange r, DateTime today, List<JournalEntry> all) {
    switch (r) {
      case StatRange.week:
        return _DateWindow(start: _addDays(today, -6), end: today);
      case StatRange.month:
        return _DateWindow(start: _addDays(today, -29), end: today);
      case StatRange.year:
        return _DateWindow(start: _addDays(today, -364), end: today);
      case StatRange.all:
        return null;
    }
  }

  Map<String, int> _computeMoodDistribution(List<JournalEntry> entries) {
    final counts = <String, int>{for (final e in moodEmojis) e: 0};
    for (final entry in entries) {
      final emoji = _firstMoodEmoji(entry);
      if (emoji == null) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  List<MoodPoint> _computeMoodOverTime(
    List<JournalEntry> entries,
    _DateWindow window,
  ) {
    final byDay = <DateTime, String>{};
    for (final entry in entries) {
      final emoji = _firstMoodEmoji(entry);
      if (emoji == null) continue;
      byDay[_normalize(entry.date)] = emoji;
    }
    final points = <MoodPoint>[];
    var cursor = window.start;
    while (!cursor.isAfter(window.end)) {
      final emoji = byDay[cursor];
      points.add(
        MoodPoint(day: cursor, score: emoji == null ? null : _moodScore(emoji)),
      );
      cursor = _addDays(cursor, 1);
    }
    return points;
  }

  List<MoodPoint> _computeMoodOverTimeUnbounded(List<JournalEntry> entries) {
    if (entries.isEmpty) return const [];
    final byDay = <DateTime, String>{};
    DateTime? earliest;
    DateTime? latest;
    for (final entry in entries) {
      final emoji = _firstMoodEmoji(entry);
      final d = _normalize(entry.date);
      earliest = earliest == null || d.isBefore(earliest) ? d : earliest;
      latest = latest == null || d.isAfter(latest) ? d : latest;
      if (emoji != null) byDay[d] = emoji;
    }
    if (earliest == null || latest == null) return const [];
    final points = <MoodPoint>[];
    var cursor = earliest;
    while (!cursor.isAfter(latest)) {
      final emoji = byDay[cursor];
      points.add(
        MoodPoint(day: cursor, score: emoji == null ? null : _moodScore(emoji)),
      );
      cursor = _addDays(cursor, 1);
    }
    return points;
  }

  List<WeekBucket> _computeEntryFrequency(
    List<JournalEntry> entries,
    _DateWindow window,
  ) {
    final counts = <DateTime, int>{};
    final start = _weekStart(window.start);
    final end = _weekStart(window.end);
    var cursor = start;
    while (!cursor.isAfter(end)) {
      counts[cursor] = 0;
      cursor = _addDays(cursor, 7);
    }
    for (final entry in entries) {
      final ws = _weekStart(entry.date);
      if (counts.containsKey(ws)) {
        counts[ws] = counts[ws]! + 1;
      }
    }
    final sorted = counts.keys.toList()..sort();
    return [
      for (final w in sorted) WeekBucket(weekStart: w, count: counts[w]!),
    ];
  }

  List<WeekBucket> _computeEntryFrequencyUnbounded(List<JournalEntry> entries) {
    if (entries.isEmpty) return const [];
    final counts = <DateTime, int>{};
    DateTime? earliest;
    DateTime? latest;
    for (final entry in entries) {
      final ws = _weekStart(entry.date);
      counts[ws] = (counts[ws] ?? 0) + 1;
      earliest = earliest == null || ws.isBefore(earliest) ? ws : earliest;
      latest = latest == null || ws.isAfter(latest) ? ws : latest;
    }
    if (earliest == null || latest == null) return const [];
    var cursor = earliest;
    while (!cursor.isAfter(latest)) {
      counts.putIfAbsent(cursor, () => 0);
      cursor = _addDays(cursor, 7);
    }
    final sorted = counts.keys.toList()..sort();
    return [
      for (final w in sorted) WeekBucket(weekStart: w, count: counts[w]!),
    ];
  }

  /// Subjective valence scale: positive ≈ 4–5, neutral ≈ 2.5–3, negative ≈ 0–1.
  /// Days with no mood entry emit `null`, not 0 — the line chart draws a gap.
  double? _moodScore(String emoji) {
    switch (emoji) {
      case '😍':
        return 5.0;
      case '😄':
        return 4.5;
      case '😊':
        return 4.0;
      case '😌':
        return 3.5;
      case '🤔':
        return 3.0;
      case '😐':
        return 2.5;
      case '😢':
        return 1.5;
      case '😠':
        return 1.0;
      case '😩':
        return 0.5;
    }
    return null;
  }

  /// First non-null mood emoji on the entry, or null when no mood
  /// block is set. Entries with multiple mood blocks (rare) take the
  /// first.
  String? _firstMoodEmoji(JournalEntry entry) {
    for (final section in entry.sections) {
      for (final block in section.blocks) {
        if (block.type != BlockType.moodTracker) continue;
        final emoji = MoodBlockContent.fromMap(block.content).emoji;
        if (emoji != null) return emoji;
      }
    }
    return null;
  }

  int _wordCountFor(JournalEntry entry) {
    var total = 0;
    final wsRegex = RegExp(r'\s+');
    for (final section in entry.sections) {
      for (final block in section.blocks) {
        if (block.type != BlockType.textBlock) continue;
        final text = TextBlockContent.fromMap(block.content).text;
        if (text.trim().isEmpty) continue;
        total += text.trim().split(wsRegex).where((w) => w.isNotEmpty).length;
      }
    }
    return total;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _addDays(DateTime d, int delta) =>
      DateTime(d.year, d.month, d.day + delta);

  /// Monday-start week, matching `table_calendar`'s default.
  DateTime _weekStart(DateTime d) {
    final n = _normalize(d);
    final daysFromMonday = (n.weekday - DateTime.monday) % 7;
    return _addDays(n, -daysFromMonday);
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}

class _DateWindow {
  const _DateWindow({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
