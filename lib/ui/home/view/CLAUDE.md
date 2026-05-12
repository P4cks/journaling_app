# lib/ui/home/view — Home screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [home_screen.dart](home_screen.dart) — `HomeScreen` (StatefulWidget) +
  `_HomeScreenState`. Standard VM-binding pattern (see [ui/CLAUDE.md](../../CLAUDE.md)).
  Layout: `SafeArea > Column [ HomeCalendar, Expanded(preview or CTA) ]`.

## What this file does

- Constructs `HomeViewModel` in `didChangeDependencies` with the
  `JournalRepository` from `AppDependencies`.
- `_openEditor(vm)` — pushes `Routes.journalEntryFor(vm.selectedDate)`,
  awaits pop, runs a sweep, then `vm.reload()` so the preview reflects
  any changes made in the editor.
- `_onMakeEntry(vm)` — opens the layout picker, calls
  `vm.createEntryWithLayout(picked)`, then pushes the editor.
- Renders either `JournalEntryView` (when `vm.currentEntry != null`) or
  `MakeEntryCta`.

## Gotchas

- **Order of operations after editor pop**: sweep first, *then* reload.
  Reload before sweep would briefly show a freshly-deleted entry until
  the sweep notification fires. Cheap operation; safe ordering.
- **`mounted` check after every `await context.push(...)`**. The user
  could navigate away mid-await — guard before touching `context` or
  `vm` again.

## When to update this file

- The post-editor-pop flow changes (e.g. show a snackbar on save).
- A new entry point off the home screen is added.
