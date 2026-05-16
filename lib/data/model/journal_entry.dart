import 'package:journaling_app_rewrite/data/model/entry_section.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final DateTime lastModified;
  final List<EntrySection> sections;
  final String? title;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.lastModified,
    required this.sections,
    this.title,
  });

  /// `copyWith` with explicit-null support for `title`: pass `clearTitle: true`
  /// to set the title back to `null` (so the entry falls back to the date).
  JournalEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? lastModified,
    List<EntrySection>? sections,
    String? title,
    bool clearTitle = false,
  }) => JournalEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    lastModified: lastModified ?? this.lastModified,
    sections: sections ?? this.sections,
    title: clearTitle ? null : (title ?? this.title),
  );

  @override
  String toString() =>
      'JournalEntry(id: $id, date: $date, title: $title, sections: ${sections.length})';
}
