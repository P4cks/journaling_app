# lib/ui/journal_entries/widgets — Entries-list widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [entry_list_tile.dart](entry_list_tile.dart) — `EntryListTile` +
  private `_DateGlyph`.
  - **Leading**: a 44×44 rounded square showing the day-of-month in
    `onPrimaryContainer` on `primaryContainer`.
  - **Title**: `entry.title` or fallback to `formatEntryDate(entry.date)`.
  - **Subtitle**: if a custom title is set, show the formatted date as
    a small line above the preview; otherwise just the preview.
  - **Preview**: `_previewText()` — walks the entry's widgets, picks
    the first non-empty `BlockType.textBlock`, collapses whitespace,
    truncates to 80 chars with `…`. Returns `"No content"` (italic)
    when no readable text exists.

## Gotchas

- **Preview only considers text blocks.** Mood-only entries fall back
  to `"No content"`. If you add a new block type with meaningful
  textual content (e.g. a quote block), update `_previewText` to look
  at it too.
- **The date glyph just shows day-of-month** — same day in different
  months reads identically. The full date is in the subtitle line.
  Don't try to put month-letters in the glyph; it gets noisy fast.

## When to update this file

- A new entry-row widget is added.
- The preview-text resolution rule changes (e.g. mood-aware previews).
