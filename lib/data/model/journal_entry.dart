import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final List<JournalBlockData> widgets;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.widgets,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    List<JournalBlockData>? widgets,
  }) => JournalEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    widgets: widgets ?? this.widgets,
  );
}
