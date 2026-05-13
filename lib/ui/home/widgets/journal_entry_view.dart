import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';

const journalEntryHeroTag = 'journal-entry-card';

class JournalEntryView extends StatelessWidget {
  const JournalEntryView({super.key, required this.entry, this.onTap});

  final JournalEntry? entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final blocks = entry?.widgets ?? const [];
    final scheme = Theme.of(context).colorScheme;

    return Hero(
      tag: journalEntryHeroTag,
      child: Material(
        color: scheme.surfaceContainerLow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: blocks.isEmpty
              ? Center(
                  child: Text(
                    'No blocks for this day yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : BlockGrid(blocks: blocks, mode: BlockMode.readOnly),
        ),
      ),
    );
  }
}
