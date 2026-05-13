import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';

class MoodTrackerWidget extends StatefulWidget {
  const MoodTrackerWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<MoodTrackerWidget> createState() => _MoodTrackerWidgetState();
}

class _MoodTrackerWidgetState extends State<MoodTrackerWidget> {
  late final PageController _controller;

  int get _initialIndex {
    final emoji = MoodBlockContent.fromMap(widget.data.content).emoji;
    final idx = emoji == null ? -1 : moodEmojis.indexOf(emoji);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialIndex,
      viewportFraction: 0.42,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(String? emoji) {
    widget.onChanged?.call(
      JournalBlockData.create(
        id: widget.data.id,
        type: widget.data.type,
        content: MoodBlockContent(emoji: emoji).toMap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = MoodBlockContent.fromMap(widget.data.content);
    if (widget.mode == BlockMode.readOnly) {
      if (content.emoji == null) {
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
        child: Text(content.emoji!, style: const TextStyle(fontSize: 56)),
      );
    }

    final selected = content.emoji;

    return PageView.builder(
      controller: _controller,
      itemCount: moodEmojis.length,
      onPageChanged: (index) {
        FocusScope.of(context).unfocus();
        _emit(moodEmojis[index]);
      },
      itemBuilder: (context, index) {
        final emoji = moodEmojis[index];
        final isSelected = emoji == selected;
        return Center(
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 180),
              child: Text(emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
        );
      },
    );
  }
}
