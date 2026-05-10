import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

class JournalEntry {
  final String id;
  final DateTime lastModified;
  final List<JournalBlockData> widgets;

  const JournalEntry({
    required this.id,
    required this.lastModified,
    required this.widgets,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? lastModified,
    List<JournalBlockData>? widgets,
  }) => JournalEntry(
    id: id ?? this.id,
    lastModified: lastModified ?? this.lastModified,
    widgets: widgets ?? this.widgets,
  );
}
