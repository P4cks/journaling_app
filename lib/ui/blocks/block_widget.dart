import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/location_block/location_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/memory_block/memory_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/mood_tracker/mood_tracker_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/photo_block/photo_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/prompt_block/prompt_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/quote_block/quote_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_block/text_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/todo_block/todo_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/weather_api/weather_api_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/weather_manual/weather_manual_widget.dart';

class BlockWidget extends StatelessWidget {
  const BlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onJumpToDate,
    this.onInteractionLockChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  /// Forwarded to blocks that have an interactive horizontal carousel
  /// (mood, manual weather). When `locked: true` the block wants the
  /// outer `JournalPager` to stop responding to horizontal swipes.
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case BlockType.textBlock:
        return TextBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.moodTracker:
        return MoodTrackerWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
        );
      case BlockType.weatherManual:
        return WeatherManualWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
        );
      case BlockType.promptBlock:
        return PromptBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.todoBlock:
        return TodoBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.quoteBlock:
        return QuoteBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.memoryBlock:
        return MemoryBlockWidget(data: data, mode: mode, onChanged: onChanged, onJumpToDate: onJumpToDate);
      case BlockType.weatherApi:
        return WeatherApiWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.photoBlock:
        return PhotoBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.locationBlock:
        return LocationBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
        );
    }
  }
}
