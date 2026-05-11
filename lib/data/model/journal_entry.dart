import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final DateTime lastModified;
  final List<JournalBlockData> widgets;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.lastModified,
    required this.widgets,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? lastModified,
    List<JournalBlockData>? widgets,
  }) => JournalEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    lastModified: lastModified ?? this.lastModified,
    widgets: widgets ?? this.widgets,
  );

  @override
  String toString() =>
      'JournalEntry(id: $id, date: $date, blocks: ${widgets.length})';
}
