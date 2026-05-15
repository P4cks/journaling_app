import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/memory_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Surfaces a random non-empty block from a past entry. The pick is
/// **locked once shown** — the first build with empty content asks the
/// repository for a random eligible block and persists the snapshot
/// into this entry's content via `onChanged`. Subsequent rebuilds read
/// the stored snapshot. Tapping the rendered memory navigates to the
/// source entry.
class MemoryBlockWidget extends StatefulWidget {
  const MemoryBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onJumpToDate,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  @override
  State<MemoryBlockWidget> createState() => _MemoryBlockWidgetState();
}

class _MemoryBlockWidgetState extends State<MemoryBlockWidget> {
  bool _picking = false;
  bool _noEligible = false;

  // Eligible source block types. Memory blocks themselves are excluded
  // to avoid memory-of-a-memory recursion. Prompt blocks are excluded
  // for now (they're shaped differently and feel weird as memories).
  static const _eligibleTypes = {BlockType.textBlock, BlockType.moodTracker};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePick();
  }

  void _maybePick() {
    final content = MemoryBlockContent.fromMap(widget.data.content);
    if (content.isSeeded || _picking || _noEligible) return;
    _picking = true;
    final repo = AppDependencies.of(context).journalRepository;
    final pick = repo.pickRandomEligibleBlock(
      beforeDate: DateTime.now(),
      eligibleTypes: _eligibleTypes,
    );
    _picking = false;
    if (pick == null) {
      setState(() => _noEligible = true);
      return;
    }
    final date = pick.date;
    final block = pick.block;
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    widget.onChanged?.call(
      JournalBlockData.create(
        id: widget.data.id,
        type: widget.data.type,
        content: MemoryBlockContent(
          sourceEntryDate: isoDate,
          sourceBlockId: block.id,
          sourceType: block.type,
          snapshotJson: block.contentJson,
        ).toMap(),
      ),
    );
  }

  void _openSource(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return;
    widget.onJumpToDate?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = MemoryBlockContent.fromMap(widget.data.content);

    if (_noEligible && !content.isSeeded) {
      return Center(
        child: Text(
          'No memories yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        ),
      );
    }

    if (!content.isSeeded) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final caption = _formatCaption(content.sourceEntryDate);
    final body = _renderSnapshot(context, content);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (widget.onJumpToDate == null || content.sourceEntryDate == null)
          ? null
          : () => _openSource(content.sourceEntryDate!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (caption != null)
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: body),
        ],
      ),
    );
  }

  String? _formatCaption(String? isoDate) {
    if (isoDate == null) return null;
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return null;
    return 'from ${formatEntryDate(parsed)}';
  }

  Widget _renderSnapshot(BuildContext context, MemoryBlockContent content) {
    final theme = Theme.of(context);
    final type = content.sourceType;
    final raw = content.snapshotJson;
    if (type == null || raw == null) {
      return Text(
        'Memory unavailable',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.disabledColor,
        ),
      );
    }
    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(raw);
      decoded = parsed is Map<String, dynamic>
          ? parsed
          : Map<String, dynamic>.from(parsed as Map);
    } catch (_) {
      return Text(
        'Memory unavailable',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.disabledColor,
        ),
      );
    }

    switch (type) {
      case BlockType.textBlock:
        final text = TextBlockContent.fromMap(decoded).text;
        return SingleChildScrollView(
          child: Text(text, style: theme.textTheme.bodySmall),
        );
      case BlockType.moodTracker:
        final emoji = MoodBlockContent.fromMap(decoded).emoji;
        return Center(
          child: Text(emoji ?? '—', style: const TextStyle(fontSize: 48)),
        );
      // Other types aren't currently picked (see `_eligibleTypes`).
      // Render a generic placeholder if the eligibility set is widened
      // later but this widget hasn't been updated.
      case BlockType.weatherManual:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
      case BlockType.quoteBlock:
      case BlockType.memoryBlock:
      case BlockType.weatherApi:
      case BlockType.photoBlock:
      case BlockType.locationBlock:
        return Text('Memory', style: theme.textTheme.bodySmall);
    }
  }
}
