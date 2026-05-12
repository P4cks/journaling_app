import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
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
    }
  }
}
