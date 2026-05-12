import 'package:journaling_app_rewrite/data/model/block_content/memory_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/quote_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/todo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

/// Block-level emptiness: a block has no meaningful content yet.
///
/// Per type:
/// - `textBlock` — text is null/empty after trimming whitespace.
/// - `moodTracker` — no mood selected.
/// - `weatherManual` — no condition selected.
/// - `promptBlock` — the user's answer is empty (prompt text alone
///   doesn't count as content).
/// - `todoBlock` — no items, or every item has empty text.
/// - `quoteBlock` — no quote text fetched/stored yet (API-generated, so
///   we treat un-fetched as empty rather than burying an entry that's
///   only-quote).
/// - `memoryBlock` — no memory seeded yet (i.e. no past eligible
///   block was available when the entry was first opened).
///
/// Unknown block types are conservatively treated as **non-empty** so we never
/// accidentally sweep something we don't yet understand.
extension JournalBlockEmptiness on JournalBlockData {
  bool get isEmpty {
    switch (type) {
      case BlockType.textBlock:
        return TextBlockContent.fromMap(content).text.trim().isEmpty;
      case BlockType.moodTracker:
        return MoodBlockContent.fromMap(content).emoji == null;
      case BlockType.weatherManual:
        return WeatherBlockContent.fromMap(content).conditionId == null;
      case BlockType.promptBlock:
        return PromptBlockContent.fromMap(content).answer.trim().isEmpty;
      case BlockType.todoBlock:
        final items = TodoBlockContent.fromMap(content).items;
        return items.isEmpty || items.every((i) => i.text.trim().isEmpty);
      case BlockType.quoteBlock:
        final q = QuoteBlockContent.fromMap(content).quote;
        return q == null || q.isEmpty;
      case BlockType.memoryBlock:
        return !MemoryBlockContent.fromMap(content).isSeeded;
    }
  }
}

/// Entry-level emptiness: every block is empty (or there are no blocks).
/// Title is intentionally ignored — a title alone does not count as content.
extension JournalEntryEmptiness on JournalEntry {
  bool get hasNoContent =>
      widgets.isEmpty || widgets.every((b) => b.isEmpty);
}
