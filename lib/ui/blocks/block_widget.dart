import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/custom_carousel_widget.dart';
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
    this.editing = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  /// Forwarded to blocks that have an interactive horizontal carousel
  /// (mood, manual weather). When `locked: true` the block wants the
  /// outer `JournalPager` to stop responding to horizontal swipes.
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// True when this block is the active edit target. Forwarded to the
  /// concrete block widgets that participate in the double-tap edit
  /// mode (text / prompt / todo / carousel-style). Ignored by action
  /// blocks (photo / location / memory) and display blocks (quote /
  /// weather-api), which keep their existing single-tap behavior.
  final bool editing;

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case BlockType.textBlock:
        return TextBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          editing: editing,
        );
      case BlockType.moodTracker:
        return MoodTrackerWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          editing: editing,
        );
      case BlockType.weatherManual:
        return WeatherManualWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          editing: editing,
        );
      case BlockType.promptBlock:
        return PromptBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          editing: editing,
        );
      case BlockType.todoBlock:
        return TodoBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          editing: editing,
        );
      case BlockType.quoteBlock:
        return QuoteBlockWidget(data: data, mode: mode, onChanged: onChanged);
      case BlockType.memoryBlock:
        return MemoryBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onJumpToDate: onJumpToDate,
        );
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
      case BlockType.customCarousel:
        return CustomCarouselWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          editing: editing,
        );
    }
  }
}
