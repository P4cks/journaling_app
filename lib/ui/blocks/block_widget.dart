import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/custom_carousel_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/habit_tracker/habit_tracker_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/location_block/location_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/memory_block/memory_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/mood_tracker/mood_tracker_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/photo_block/photo_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/prompt_block/prompt_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/quote_block/quote_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/streak_block/streak_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_block/text_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/todo_block/todo_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/voice_block/voice_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/weather_api/weather_api_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/weather_manual/weather_manual_widget.dart';

/// Dispatcher that constructs the concrete block widget for a given
/// `BlockType`. Forwards every parameter the concrete widgets need —
/// including the new `expanded` flag (whether the body is rendered
/// inside the expanded route) and `onRequestExitEdit` (which carousels
/// fire after the 1.5 s auto-collapse to clear in-place edit mode).
///
/// The set of props on this widget mirrors `BlockRenderContext` at
/// [chrome/block_render_context.dart](chrome/block_render_context.dart);
/// the context bundle is consumed directly by the expanded route, and
/// `BlockWidget` keeps the legacy parameter shape for the grid + the
/// layout editor.
class BlockWidget extends StatelessWidget {
  const BlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onJumpToDate,
    this.onInteractionLockChanged,
    this.onRequestExitEdit,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  /// Forwarded to carousel blocks. When `locked: true` the block wants
  /// the outer `JournalPager` to stop responding to horizontal swipes.
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// Fires when a carousel auto-collapses after 1.5 s of inactivity.
  /// In-place edit-mode hosts use this to clear `_editingBlockId` so
  /// the outline disappears in lock-step with the carousel.
  final VoidCallback? onRequestExitEdit;

  /// Push-the-expanded-route callback. Each block widget wires this
  /// into its own `GestureDetector(onDoubleTap)` so the framework
  /// handles tap-vs-double-tap disambiguation natively (single tap
  /// fires the block's engage action after `kDoubleTapTimeout`,
  /// double tap fires this immediately).
  final VoidCallback? onDoubleTap;

  /// True when this block is the active edit target.
  final bool editing;

  /// True when this block is rendered inside the expanded route. Only
  /// a few blocks change behavior between in-place and expanded
  /// (carousel's auto-collapse).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case BlockType.textBlock:
        return TextBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
          editing: editing,
        );
      case BlockType.moodTracker:
        return MoodTrackerWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          onRequestExitEdit: onRequestExitEdit,
          onDoubleTap: onDoubleTap,
          editing: editing,
          expanded: expanded,
        );
      case BlockType.weatherManual:
        return WeatherManualWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          onRequestExitEdit: onRequestExitEdit,
          onDoubleTap: onDoubleTap,
          editing: editing,
          expanded: expanded,
        );
      case BlockType.promptBlock:
        return PromptBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
          editing: editing,
        );
      case BlockType.todoBlock:
        return TodoBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
          editing: editing,
          expanded: expanded,
        );
      case BlockType.quoteBlock:
        return QuoteBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
        );
      case BlockType.memoryBlock:
        return MemoryBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onJumpToDate: onJumpToDate,
          onDoubleTap: onDoubleTap,
          expanded: expanded,
        );
      case BlockType.weatherApi:
        return WeatherApiWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
        );
      case BlockType.photoBlock:
        return PhotoBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
        );
      case BlockType.locationBlock:
        return LocationBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
        );
      case BlockType.customCarousel:
        return CustomCarouselWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onInteractionLockChanged: onInteractionLockChanged,
          onRequestExitEdit: onRequestExitEdit,
          onDoubleTap: onDoubleTap,
          editing: editing,
          expanded: expanded,
        );
      case BlockType.habitTracker:
        return HabitTrackerWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
          editing: editing,
          expanded: expanded,
        );
      case BlockType.streakBlock:
        return StreakBlockWidget(
          data: data,
          mode: mode,
          onDoubleTap: onDoubleTap,
        );
      case BlockType.voiceBlock:
        return VoiceBlockWidget(
          data: data,
          mode: mode,
          onChanged: onChanged,
          onDoubleTap: onDoubleTap,
        );
    }
  }
}
