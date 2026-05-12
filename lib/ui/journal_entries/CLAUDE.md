# lib/ui/journal_entries — All-entries list (plural)

The third tab. Sectioned list of every entry the user has, grouped
by month, newest-first. **Plural** — sibling of [`journal_entry/`](../journal_entry/CLAUDE.md)
(singular, the fullscreen editor).

```
journal_entries/
├── view/         JournalEntriesScreen — Scaffold + sliver-based list
├── view_model/   JournalEntriesViewModel — section building
└── widgets/      EntryListTile
```

## Behaviour

- Pulls all entries from `JournalRepository`, sorts newest-first,
  groups into month buckets, displays each bucket under a header
  showing `"<Long Month> <year>"`.
- Each row is an `EntryListTile`: a date glyph, the entry's title (or
  the formatted date when no title), and a one-line preview pulled
  from the first non-empty `BlockType.textBlock`.
- Tap → `context.push(Routes.journalEntryFor(entry.date))`. The editor
  Hero would morph cleanly *if* this screen wrapped its preview in
  the Hero — currently it doesn't, the editor still picks up the tag
  from elsewhere (no morph from this screen, just a push).
- Empty state: phosphor `bookOpen` + nudge text.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `JournalEntriesScreen` (+ private `_SectionedList`, `_MonthHeader`, `_EmptyState`)
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `JournalEntriesViewModel`, `MonthSection`
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `EntryListTile`

## Implementation details

- The screen uses `CustomScrollView` with one `SliverToBoxAdapter`
  per month header and one `SliverList.builder` per month. Keeps each
  month's tiles lazily-built.
- Section building runs in the VM (`_rebuild`), not the widget — the
  build path stays cheap on every rebuild. Recomputed on every
  repository notification (which is fine for the current entry
  volumes).

## Gotchas

- **The month-bucket key is `year * 100 + month`** (a single int).
  Safe as long as months stay in 1..12 — which they will, they come
  from a `DateTime`. Don't try to fancy this into a `(int, int)`
  record without a cheap hash story.
- **Preview text strips whitespace + truncates at 80 chars.** If you
  add markdown / formatted blocks, route the preview computation
  through the typed wrapper, not raw `contentJson` parsing.

## When to update this file

- The grouping scheme changes (e.g. group by year, by tag, by mood).
- A new row affordance is added (swipe actions, multi-select).
- The screen starts participating in the Hero morph.
