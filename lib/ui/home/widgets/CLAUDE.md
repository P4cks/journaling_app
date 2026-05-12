# lib/ui/home/widgets — Home-screen widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [home_calendar.dart](home_calendar.dart) — `HomeCalendar` (StatefulWidget).
  Wraps `package:table_calendar`'s `TableCalendar`. Holds its own
  `CalendarFormat` (week/month toggle); date selection delegates to
  the VM. **`lastDay` is dynamic** — `today` by default, `2100-12-31`
  when `DebugSettings.unlockAllDays` is on. The whole widget is rebuilt
  via a `ListenableBuilder(listenable: debug)` so toggling the debug
  flag flips the future-day gate live.
  - **Entry dots** are produced by `eventLoader`. We return a const
    `[Object()]` sentinel for days that have entries — `TableCalendar`
    only checks list length when deciding whether to paint, so the
    element value doesn't matter. Allocating fresh lists per call
    would cause unnecessary churn.
  - All colours come from `Theme.of(context).colorScheme`. The
    selected-day decoration is a filled accent disc; today is an
    outlined accent disc; markers are 5px primary dots.
- [journal_entry_view.dart](journal_entry_view.dart) — `JournalEntryView`.
  Read-only preview for the home screen. Exports the
  `journalEntryHeroTag` constant; the fullscreen editor `show`s it
  from this file so both ends agree.
  - Wraps a `BlockGrid(mode: BlockMode.readOnly)` in a `Material(color: scheme.surfaceContainerLow)`
    (matches the editor body's surface) + `InkWell` for ripples. Empty
    blocks show a fallback message.
- [make_entry_cta.dart](make_entry_cta.dart) — `MakeEntryCta`. Centered
  icon + title + subtitle + tonal button. Used by both the home screen
  (when the selected day has no entry) and the editor (when reached
  via deep link to a day without one) — `title` / `subtitle` /
  `buttonLabel` are configurable for that reason.

## Gotchas

- **Don't replace the `eventLoader` sentinel with a list of entries.**
  `TableCalendar` only uses list length; building a per-day entries
  list each day would walk the entire entry collection per cell.
- **The Hero tag is a const string**, not a per-entry id. Only one
  entry-view morph is ever in flight at a time (you can't have two
  fullscreen editors stacked), so a stable tag is correct. Per-id
  tags would break the morph between home preview and editor.

## When to update this file

- A new home-screen widget is added.
- The calendar config changes (new format, custom builders for cell
  rendering, etc.).
- The Hero contract changes (e.g. distinct tags per entry).
