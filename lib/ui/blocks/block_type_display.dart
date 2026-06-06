import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/habit_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/location_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/memory_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/photo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/quote_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_api_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/todo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Built-in block types locked behind Pro. Edit this set to change the
/// free/Pro split — [BlockTypeDisplay.isProOnly] derives from it. Free
/// users get every other built-in block; only these stay Pro. (GUS-34)
const Set<BlockType> kProOnlyBlockTypes = {
  BlockType.weatherApi, // "Weather (live)"
  BlockType.quoteBlock, // "Quote of the day"
};

extension BlockTypeDisplay on BlockType {
  String get label {
    switch (this) {
      case BlockType.textBlock:
        return 'Text';
      case BlockType.moodTracker:
        return 'Mood Tracker';
      case BlockType.weatherManual:
        return 'Weather';
      case BlockType.promptBlock:
        return 'Prompt';
      case BlockType.todoBlock:
        return 'Todo';
      case BlockType.quoteBlock:
        return 'Quote of the day';
      case BlockType.memoryBlock:
        return 'Memory';
      case BlockType.weatherApi:
        return 'Weather (live)';
      case BlockType.photoBlock:
        return 'Photo';
      case BlockType.locationBlock:
        return 'Location';
      case BlockType.customCarousel:
        return 'Custom carousel';
      case BlockType.habitTracker:
        return 'Habit';
      case BlockType.streakBlock:
        return 'Streak';
    }
  }

  HugeIconData get icon {
    switch (this) {
      case BlockType.textBlock:
        return HugeIcons.strokeRoundedTextFont;
      case BlockType.moodTracker:
        return HugeIcons.strokeRoundedSmile;
      case BlockType.weatherManual:
        return HugeIcons.strokeRoundedSun01;
      case BlockType.promptBlock:
        return HugeIcons.strokeRoundedQuestion;
      case BlockType.todoBlock:
        return HugeIcons.strokeRoundedCheckList;
      case BlockType.quoteBlock:
        return HugeIcons.strokeRoundedQuotes;
      case BlockType.memoryBlock:
        return HugeIcons.strokeRoundedTime04;
      case BlockType.weatherApi:
        return HugeIcons.strokeRoundedSunCloud01;
      case BlockType.photoBlock:
        return HugeIcons.strokeRoundedImage01;
      case BlockType.locationBlock:
        return HugeIcons.strokeRoundedMapPin;
      case BlockType.customCarousel:
        return HugeIcons.strokeRoundedGrid;
      case BlockType.habitTracker:
        return HugeIcons.strokeRoundedCheckmarkCircle02;
      case BlockType.streakBlock:
        return HugeIcons.strokeRoundedFire;
    }
  }

  String get description {
    switch (this) {
      case BlockType.textBlock:
        return 'A free-form text entry.';
      case BlockType.moodTracker:
        return 'Tap to log how you felt today.';
      case BlockType.weatherManual:
        return 'Pick today’s weather.';
      case BlockType.promptBlock:
        return 'Answer a recurring question.';
      case BlockType.todoBlock:
        return 'Checkable list of tasks.';
      case BlockType.quoteBlock:
        return 'A fresh quote each day.';
      case BlockType.memoryBlock:
        return 'A random memory from a past day.';
      case BlockType.weatherApi:
        return 'Auto-fetched weather for your location.';
      case BlockType.photoBlock:
        return 'Attach a photo from your camera or gallery.';
      case BlockType.locationBlock:
        return 'Long-press the map to drop a pin.';
      case BlockType.customCarousel:
        return 'A carousel of your own icons or emojis.';
      case BlockType.habitTracker:
        return 'Cross off a daily habit and build a streak.';
      case BlockType.streakBlock:
        return 'Shows your current streak and your best.';
    }
  }

  JournalBlockData sampleData({required String id}) {
    switch (this) {
      case BlockType.textBlock:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const TextBlockContent(
            text: 'Today I went for a walk in the park and noticed…',
          ).toMap(),
        );
      case BlockType.moodTracker:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const MoodBlockContent(emoji: '😄').toMap(),
        );
      case BlockType.weatherManual:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const WeatherBlockContent(conditionId: 'sun').toMap(),
        );
      case BlockType.promptBlock:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const PromptBlockContent(
            prompt: 'What surprised you today?',
            answer: '',
          ).toMap(),
        );
      case BlockType.todoBlock:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const TodoBlockContent(
            items: [
              TodoItem(id: 'sample-1', text: 'Morning walk', done: true),
              TodoItem(id: 'sample-2', text: 'Read 10 pages'),
              TodoItem(id: 'sample-3', text: 'Stretch'),
            ],
          ).toMap(),
        );
      case BlockType.quoteBlock:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const QuoteBlockContent(
            quote: 'The only way to do great work is to love what you do.',
            author: 'Steve Jobs',
          ).toMap(),
        );
      case BlockType.memoryBlock:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const MemoryBlockContent(
            sourceEntryDate: '2025-09-14',
            sourceBlockId: 'sample-text',
            sourceType: BlockType.textBlock,
            snapshotJson:
                '{"text":"Saw the first frost on the field this morning."}',
          ).toMap(),
        );
      case BlockType.weatherApi:
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const WeatherApiBlockContent(
            conditionId: 'partly_cloudy',
            temperatureC: 18,
            cityName: 'Your city',
          ).toMap(),
        );
      case BlockType.photoBlock:
        // No real file path in the preview — the widget will render
        // its empty-state affordance instead.
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const PhotoBlockContent().toMap(),
        );
      case BlockType.locationBlock:
        // Sample pin sits in the middle of the Atlantic so the preview
        // shows a recognisable Mercator view of Europe + Americas.
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const LocationBlockContent(
            latitude: 40.7,
            longitude: -30,
          ).toMap(),
        );
      case BlockType.customCarousel:
        // No definitionId — the picker preview renders the deleted
        // placeholder. Real picker tiles in the Add Block sheet
        // override this with a per-definition preview (handled in
        // add_block_sheet.dart).
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const CustomCarouselBlockContent(
            selected: CarouselItem(kind: CarouselItemKind.emoji, value: '⚡'),
          ).toMap(),
        );
      case BlockType.habitTracker:
        // No definitionId — the widget renders a generic checked
        // preview. Real tiles in the Add Block sheet override this
        // with a per-definition preview (handled in add_block_sheet.dart).
        return JournalBlockData.create(
          id: id,
          type: this,
          content: const HabitBlockContent(completed: true).toMap(),
        );
      case BlockType.streakBlock:
        // No per-entry content — the widget reads the live streak off
        // the repository. The preview renders whatever the user's real
        // streak is.
        return JournalBlockData.create(id: id, type: this, content: const {});
    }
  }

  /// Whether this block participates in the double-tap engage flow.
  /// **Every block type returns true** — even pure-display blocks
  /// (quote, weather-api) are expandable so the user can read them
  /// in larger form inside the route. The expanded view for
  /// display-only blocks is just the body rendered bigger; no
  /// editing affordance, no inner taps wired up.
  bool get usesEditMode {
    switch (this) {
      case BlockType.textBlock:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.customCarousel:
      case BlockType.habitTracker:
      case BlockType.photoBlock:
      case BlockType.locationBlock:
      case BlockType.memoryBlock:
      case BlockType.quoteBlock:
      case BlockType.weatherApi:
      case BlockType.streakBlock:
        return true;
    }
  }

  /// True for blocks that fire a single one-shot action when engaged
  /// rather than hosting a sustained interactive UI. With the "expand
  /// on edit" setting **OFF**, the host fires the action immediately
  /// on double-tap and skips setting `_editingBlockId` — there's no
  /// in-place edit mode to maintain. With the setting **ON**, the
  /// expanded route is pushed and the user taps the inner widget to
  /// fire the action inside the route.
  ///
  /// Location is intentionally NOT in this set: its "interaction" is
  /// long-press on the map, which is already always available in
  /// editable entries. Double-tap on a location block falls through
  /// to the standard in-place edit flow (outline + map remains
  /// interactive — i.e., a no-op in practice for setting OFF).
  bool get isActionBlock {
    switch (this) {
      case BlockType.photoBlock:
      case BlockType.memoryBlock:
        return true;
      case BlockType.textBlock:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.customCarousel:
      case BlockType.habitTracker:
      case BlockType.locationBlock:
      case BlockType.quoteBlock:
      case BlockType.weatherApi:
      case BlockType.streakBlock:
        return false;
    }
  }

  /// Whether this block type is locked behind Pro. Derived from
  /// [kProOnlyBlockTypes] so the free/Pro split is one declarative edit.
  /// The add-block sheet greys + badges locked cells and presents the
  /// paywall on tap rather than hiding them (discoverability). (GUS-19,
  /// GUS-34)
  ///
  /// `customCarousel` is intentionally never in [kProOnlyBlockTypes]:
  /// custom blocks are gated by *count* (1 free; see
  /// `kFreeMaxCustomBlocks` in pro_gate.dart), not by a blanket Pro flag.
  bool get isProOnly => kProOnlyBlockTypes.contains(this);

  /// Whether editing this block raises the keyboard. Drives the
  /// expanded-overlay layout: keyboard-using blocks sit in the top half
  /// (keyboard fits below); other blocks sit centered.
  bool get usesKeyboardOnEdit {
    switch (this) {
      case BlockType.textBlock:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
        return true;
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.customCarousel:
      case BlockType.habitTracker:
      case BlockType.photoBlock:
      case BlockType.locationBlock:
      case BlockType.memoryBlock:
      case BlockType.quoteBlock:
      case BlockType.weatherApi:
      case BlockType.streakBlock:
        return false;
    }
  }
}
