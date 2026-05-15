import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';

class MoodTrackerWidget extends StatelessWidget {
  const MoodTrackerWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onInteractionLockChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  @override
  Widget build(BuildContext context) {
    final selected = MoodBlockContent.fromMap(data.content).emoji;

    if (mode == BlockMode.readOnly) {
      return _buildCollapsed(context, selected);
    }

    return CollapsibleCarouselBlock<String>(
      blockId: data.id,
      options: moodEmojis,
      selected: selected,
      collapsedBuilder: _buildCollapsed,
      itemBuilder: (ctx, emoji, isSelected) => AnimatedScale(
        scale: isSelected ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 180),
          child: Text(emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
      onSelected: (emoji) => onChanged?.call(
        JournalBlockData.create(
          id: data.id,
          type: data.type,
          content: MoodBlockContent(emoji: emoji).toMap(),
        ),
      ),
      onInteractionLockChanged: onInteractionLockChanged,
    );
  }

  Widget _buildCollapsed(BuildContext context, String? emoji) {
    if (emoji == null) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 40,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 56)),
    );
  }
}
