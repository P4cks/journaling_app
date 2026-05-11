import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';

class MoodTrackerWidget extends StatelessWidget {
  const MoodTrackerWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  void _emit(Mood? mood) {
    final updated = JournalBlockData.create(
      id: data.id,
      type: data.type,
      content: MoodBlockContent(mood: mood).toMap(),
    );
    onChanged?.call(updated);
  }

  IconData _iconFor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Icons.sentiment_very_satisfied;
      case Mood.neutral:
        return Icons.sentiment_neutral;
      case Mood.sad:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  String _labelFor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'Happy';
      case Mood.neutral:
        return 'Neutral';
      case Mood.sad:
        return 'Sad';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = MoodBlockContent.fromMap(data.content);

    if (mode == BlockMode.readOnly) {
      if (content.mood == null) {
        return Text(
          'No mood',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).disabledColor,
          ),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(content.mood!)),
          const SizedBox(width: 8),
          Text(_labelFor(content.mood!)),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      children: Mood.values.map((m) {
        final selected = m == content.mood;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(m), size: 18),
              const SizedBox(width: 4),
              Text(_labelFor(m)),
            ],
          ),
          selected: selected,
          onSelected: (isSelected) {
            FocusScope.of(context).unfocus();
            _emit(isSelected ? m : null);
          },
        );
      }).toList(),
    );
  }
}
