import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

class JournalEntryCollection {
  final DateTime date;
  final List<JournalEntry> journalEntriesOnDate;

  JournalEntryCollection({required this.date, required this.journalEntriesOnDate});

  JournalEntryCollection copyWith({
    DateTime? date,
    List<JournalEntry>? journalEntriesOnDate,
  }) {
    return JournalEntryCollection(
      date: date ?? this.date,
      journalEntriesOnDate: journalEntriesOnDate ?? this.journalEntriesOnDate,
    );
  }
}