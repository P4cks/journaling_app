import 'package:flutter/widgets.dart';
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
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.textBlock:
        return PhosphorIconsDuotone.textAa;
      case BlockType.moodTracker:
        return PhosphorIconsDuotone.smiley;
      case BlockType.weatherManual:
        return PhosphorIconsDuotone.sun;
      case BlockType.promptBlock:
        return PhosphorIconsDuotone.question;
      case BlockType.todoBlock:
        return PhosphorIconsDuotone.listChecks;
      case BlockType.quoteBlock:
        return PhosphorIconsDuotone.quotes;
      case BlockType.memoryBlock:
        return PhosphorIconsDuotone.clockCounterClockwise;
      case BlockType.weatherApi:
        return PhosphorIconsDuotone.cloudSun;
      case BlockType.photoBlock:
        return PhosphorIconsDuotone.image;
      case BlockType.locationBlock:
        return PhosphorIconsDuotone.mapPin;
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
    }
  }
}
