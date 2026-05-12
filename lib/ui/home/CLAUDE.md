# lib/ui/home — Home screen

The landing tab. Layout: `TableCalendar` at the top, an
`Expanded` block-grid preview (or "Make entry" CTA) below. Tapping
the preview Hero-animates into the fullscreen editor at
`/journal/yyyy-mm-dd`.

```
home/
├── view/         HomeScreen — wires VM, calendar, preview, CTA
├── view_model/   HomeViewModel — selected/focused date, current entry, entriesByDay
└── widgets/      HomeCalendar, JournalEntryView (with Hero), MakeEntryCta
```

## Behaviour overview

- **Selected date** drives both the calendar highlight and the preview
  shown below. Default: today.
- **Entry preview** (`JournalEntryView`) — when the selected day has
  an entry, renders the blocks in read-only mode inside a `Hero` tagged
  `journalEntryHeroTag`. Tap to push the editor.
- **Make entry CTA** (`MakeEntryCta`) — shown when the selected day
  has no entry. Tap opens the layout-picker sheet, creates the entry
  with the picked layout, then immediately pushes the editor.
- **Empty-past-entry sweep** runs on editor pop (in addition to cold
  start and app-resume). Catches the "user cleared all blocks on a
  past day" case immediately. See [data/repositories/CLAUDE.md](../../data/repositories/CLAUDE.md).
- **Calendar dots** — `TableCalendar.eventLoader` is fed
  `vm.entriesByDay` (a `Set<DateTime>` of normalized days). Empty
  entries *are* included while they exist (today's drafts), and drop
  out after a sweep deletes them.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `HomeScreen`
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `HomeViewModel`
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `HomeCalendar`, `JournalEntryView`, `MakeEntryCta`

## Hero animation contract

The home preview and the editor's body both wrap the same `BlockGrid`
in `Material(color: surfaceContainerLow)` and share the same
`Hero(tag: journalEntryHeroTag)`. Both ends must use the **same
surface color and same child structure** or the morph looks like a
crossfade instead of a continuous expansion. The tag constant is
re-exported from `journal_entry_view.dart`; the editor `show`s it from
there. Don't duplicate the constant.

## Gotchas

- **`TableCalendar`'s `lastDay` is controlled by `DebugSettings.unlockAllDays`.**
  Default is today; with the flag on it's 2100-12-31. The calendar
  itself disables future-day cells when `lastDay < that day`, so
  flipping `unlockAllDays` while the calendar is mounted needs to
  rebuild — that's why `HomeCalendar` wraps in `ListenableBuilder(listenable: debug)`.
- **`HomeViewModel.createEntryWithLayout` notifies twice**: once
  immediately (so the screen sees the new entry without waiting), and
  once when the repository's notification ticks back. The second is a
  no-op (state unchanged). Don't try to dedup — the first one matters
  for snappy UX.

## When to update this file

- The home layout structure changes (calendar location, sticky elements).
- A new entry point off the home tab is added.
- The Hero tag contract changes.
