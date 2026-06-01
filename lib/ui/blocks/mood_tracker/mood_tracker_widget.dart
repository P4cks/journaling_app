import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/carousel_block_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

class MoodTrackerWidget extends StatelessWidget {
  const MoodTrackerWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onInteractionLockChanged,
    this.onRequestExitEdit,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;
  final VoidCallback? onRequestExitEdit;
  final VoidCallback? onDoubleTap;
  final bool editing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final settings = AppDependencies.of(context).blockSettings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => CarouselBlockScaffold<String>(
        blockId: data.id,
        mode: mode,
        title: settings.carouselTitlesEnabled ? 'How are you feeling?' : null,
        options: moodEmojis,
        selected: MoodBlockContent.fromMap(data.content).emoji,
        itemBuilder: (ctx, emoji, _) =>
            Text(emoji, style: const TextStyle(fontSize: 56)),
        onSelected: (emoji) => onChanged?.call(
          data.copyWith(content: MoodBlockContent(emoji: emoji).toMap()),
        ),
        onInteractionLockChanged: onInteractionLockChanged,
        onRequestExitEdit: expanded ? null : onRequestExitEdit,
        onDoubleTap: onDoubleTap,
        editing: editing || expanded,
        // Auto-collapse in both grid and expanded mode. In the
        // expanded route the carousel collapses to the centred glyph
        // after 1.5 s of inactivity (matching the grid behavior); the
        // user re-engages by tapping it. The route itself stays open
        // — `onRequestExitEdit` is null in expanded mode so the
        // collapse-timer only flips the picker visually.
        autoCollapse: true,
      ),
    );
  }
}
