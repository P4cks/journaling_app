import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

/// Block-level emptiness: a block has no meaningful content yet.
///
/// Per type:
/// - `textBlock` — text is null/empty after trimming whitespace.
/// - `moodTracker` — no mood selected.
///
/// Unknown block types are conservatively treated as **non-empty** so we never
/// accidentally sweep something we don't yet understand.
extension JournalBlockEmptiness on JournalBlockData {
  bool get isEmpty {
    switch (type) {
      case BlockType.textBlock:
        return TextBlockContent.fromMap(content).text.trim().isEmpty;
      case BlockType.moodTracker:
        return MoodBlockContent.fromMap(content).mood == null;
    }
  }
}

/// Entry-level emptiness: every block is empty (or there are no blocks).
/// Title is intentionally ignored — a title alone does not count as content.
extension JournalEntryEmptiness on JournalEntry {
  bool get hasNoContent =>
      widgets.isEmpty || widgets.every((b) => b.isEmpty);
}
