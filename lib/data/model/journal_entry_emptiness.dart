import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/habit_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/location_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/memory_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/photo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/quote_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_api_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/todo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';

/// Whether a block type requires explicit user action (typing, tapping,
/// dropping a pin, adding a photo) to be populated. Used by
/// [JournalEntryEmptiness.hasNoContent] to decide whether the user
/// actually did anything with the entry — auto-seeded blocks (quote,
/// memory, weather API) populate themselves and must NOT keep an
/// otherwise-untouched entry alive past the midnight sweep.
///
/// **When adding a new BlockType, you MUST also add a case here.** Ask
/// yourself: does the block's content come from explicit user action,
/// or does it seed itself from an API / generator / repository state?
///   - User typing, tapping, picking, dropping → `true`
///   - API fetch, random pick from past entries, scheduled poll → `false`
///
/// If unsure, ask. Getting this wrong means either (a) entries silently
/// vanish at midnight despite the user filling them in, or (b) entries
/// accumulate forever because an API block keeps them alive.
extension BlockTypeInteraction on BlockType {
  bool get isUserInteractive {
    switch (this) {
      case BlockType.textBlock:
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
      case BlockType.photoBlock:
      case BlockType.locationBlock:
      case BlockType.customCarousel:
      case BlockType.habitTracker:
        return true;
      case BlockType.quoteBlock:
      case BlockType.memoryBlock:
      case BlockType.weatherApi:
      // Streak block seeds itself from repository state — it is not
      // user-interactive, so it must not keep an otherwise-empty entry
      // alive past the midnight sweep.
      case BlockType.streakBlock:
        return false;
    }
  }
}

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
/// - `weatherApi` — no observation fetched/stored yet (API-generated,
///   so we don't keep an entry alive just because of a failed fetch).
/// - `photoBlock` — no photo path stored yet.
/// - `locationBlock` — no pin dropped yet (lat/lon both absent).
/// - `customCarousel` — no `selected` item picked yet. The
///   `definitionId` orphaning case (definition deleted) still counts
///   as empty: the user can't interact with a missing definition.
/// - `habitTracker` — not crossed off yet (`completed == false`). The
///   orphaned-definition case is also empty (nothing to interact with).
/// - `streakBlock` — never empty (it always renders the live streak);
///   non-interactive, so this classification never keeps an entry alive.
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
      case BlockType.weatherApi:
        return !WeatherApiBlockContent.fromMap(content).isFetched;
      case BlockType.photoBlock:
        return !PhotoBlockContent.fromMap(content).hasPhoto;
      case BlockType.locationBlock:
        return !LocationBlockContent.fromMap(content).hasPin;
      case BlockType.customCarousel:
        return CustomCarouselBlockContent.fromMap(content).selected == null;
      case BlockType.habitTracker:
        return !HabitBlockContent.fromMap(content).completed;
      case BlockType.streakBlock:
        // Always renders a live streak (even 0). Never "empty" — but it
        // is non-interactive, so this never keeps an entry alive anyway.
        return false;
    }
  }
}

/// Entry-level emptiness: the user has done nothing with this entry.
/// Only [BlockTypeInteraction.isUserInteractive] blocks are considered —
/// auto-seeded blocks (quote, memory, weather API) are skipped so an
/// otherwise-untouched entry doesn't survive the midnight sweep just
/// because an API succeeded. Returns true when there are no sections,
/// or every user-interactive block is empty.
/// Title is intentionally ignored — a title alone does not count as content.
extension JournalEntryEmptiness on JournalEntry {
  bool get hasNoContent {
    if (sections.isEmpty) return true;
    for (final section in sections) {
      for (final block in section.blocks) {
        if (!block.type.isUserInteractive) continue;
        if (!block.isEmpty) return false;
      }
    }
    return true;
  }
}
