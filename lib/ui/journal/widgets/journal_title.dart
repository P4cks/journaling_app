import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/editor_title.dart';
import 'package:journaling_app_rewrite/ui/theme/app_typography.dart';

/// AppBar leading title region for the main journal screen.
///
/// Stacks the inline-editable [EditorTitle] above a smaller, non-editable
/// date line. When no entry exists yet for the date, the editable field
/// is suppressed (no entry → nothing to attach the title to); the date
/// becomes the primary text and the subtitle is hidden so the line isn't
/// duplicated.
class JournalTitle extends StatelessWidget {
  const JournalTitle({
    super.key,
    required this.date,
    required this.title,
    required this.editable,
    required this.hasEntry,
    required this.onChanged,
  });

  final DateTime date;
  final String? title;
  final bool editable;
  final bool hasEntry;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The Fraunces dateline — the journal's quiet date voice (GUS-87).
    final subtitleStyle = AppText.entryDate.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (!hasEntry) {
      // No title to attach yet, so the date itself is the page's nameplate.
      return Text(
        formatEntryDate(date),
        style: AppText.entryTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Only show the date subtitle when a real title sits above it. With no
    // title, EditorTitle already renders the date as the primary nameplate,
    // so a subtitle would just duplicate it (GUS-87).
    final hasTitle = (title ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        EditorTitle(
          title: title,
          date: date,
          editable: editable,
          onChanged: onChanged,
        ),
        if (hasTitle) Text(formatEntryDate(date), style: subtitleStyle),
      ],
    );
  }
}
