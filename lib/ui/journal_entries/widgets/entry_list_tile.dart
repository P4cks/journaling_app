import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';

class EntryListTile extends StatelessWidget {
  const EntryListTile({super.key, required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  /// Best-effort preview: first non-empty text block's text, trimmed and
  /// clipped to a short snippet. Falls back to "No content" when no
  /// readable text is present.
  String _previewText() {
    for (final section in entry.sections) {
      for (final block in section.blocks) {
        if (block.type != BlockType.textBlock) continue;
        final text = TextBlockContent.fromMap(block.content).text.trim();
        if (text.isEmpty) continue;
        // Collapse whitespace + truncate so the preview fits on one line.
        final flat = text.replaceAll(RegExp(r'\s+'), ' ');
        return flat.length > 80 ? '${flat.substring(0, 80)}…' : flat;
      }
    }
    return 'No content';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = entry.title ?? formatEntryDate(entry.date);
    final showDateSubtitle = entry.title != null;
    final preview = _previewText();
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _DateGlyph(date: entry.date),
      title: Text(
        title,
        style: theme.textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDateSubtitle)
            Text(
              formatEntryDate(entry.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          Text(
            preview,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: preview == 'No content'
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DateGlyph extends StatelessWidget {
  const _DateGlyph({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        date.day.toString(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
