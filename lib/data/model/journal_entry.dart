import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final DateTime lastModified;
  final List<JournalBlockData> widgets;
  final String? title;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.lastModified,
    required this.widgets,
    this.title,
  });

  /// `copyWith` with explicit-null support for `title`: pass `clearTitle: true`
  /// to set the title back to `null` (so the entry falls back to the date).
  JournalEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? lastModified,
    List<JournalBlockData>? widgets,
    String? title,
    bool clearTitle = false,
  }) => JournalEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    lastModified: lastModified ?? this.lastModified,
    widgets: widgets ?? this.widgets,
    title: clearTitle ? null : (title ?? this.title),
  );

  @override
  String toString() =>
      'JournalEntry(id: $id, date: $date, title: $title, blocks: ${widgets.length})';
}
