# lib/ui/journal/view — Main journal screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [main_journal_screen.dart](main_journal_screen.dart) —
  `MainJournalScreen` (StatefulWidget) + `_MainJournalScreenState`.
  Standard VM-binding pattern (see [ui/CLAUDE.md](../../CLAUDE.md)).

## Composition

```
Scaffold
├── AppBar
│   ├── title: JournalTitle (editable title + date subtitle)
│   └── actions: Change-layout (when editable + hasEntry),
│                Entries icon (push /entries),
│                ProfileMenuButton (popup with streak/auth + items)
├── body: Material(surfaceContainerLow) + SizedBox.expand
│         └── GestureDetector (unfocus-on-tap)
│              └── hasEntry
│                   ? JournalPager(vm, modeFor: …)
│                   : editable ? MakeEntryCta : NoEntryReadOnly
└── bottomNavigationBar: CalendarBottomBar(selectedDate, entriesByDay, onDateSelected)
```

## Edit-mode formula

`editable = _isToday(date) || debug.unlockAllDays`

Same gate as before the merge. Used for two decisions:

1. Whether the title is editable.
2. Whether the body is `MakeEntryCta` (editable + no entry) or
   `NoEntryReadOnly` (read-only + no entry).
3. Whether each pager page uses `BlockMode.editable` or `BlockMode.readOnly`
   (per-entry — the pager itself can span past + present, so the mode
   is computed per page).

## Actions

- `_onMakeEntry()` — opens the layout picker, calls
  `vm.createWithLayout`. The repository notification fans out to the
  VM, which adds the new entry to its `entries` list; the screen
  rebuilds with the pager pointing at the new entry.
- `_showChangeLayoutSheet()` — opens the picker → confirm dialog →
  `vm.applyLayout`. Destructive; always confirms.
- `_openEntries()` — `context.push(Routes.entries)`. The list tile
  taps then `push` back to `/journal/yyyy-mm-dd`, so the back stack is
  Entries → MainJournalScreen (with that date).

## Gotchas

- **No Hero animation**. The pre-merge screen used `Hero(journalEntryHeroTag)`
  to morph from a Home preview to the editor; with the screens merged
  there is no separate preview to morph from. Don't reintroduce a
  Hero — it would only confuse the swipe pager's animation.
- **The body's surface color is `scheme.surfaceContainerLow`**, matching
  the old editor (and the old preview). Keep it consistent so any
  future cross-fade or shared-axis transition lands on the same
  surface tone.
- **`debug.unlockAllDays` is read inside `ListenableBuilder`**, so
  flipping the flag rebuilds without reload. The pager's per-page
  mode picks it up too.
- **`!mounted` guard after every `await context.push/showDialog`** —
  the user could pop the screen mid-await.

## When to update this file

- New AppBar actions are added.
- The body composition gains new branches (sidebar, sticky header).
- The pager replaces the simple BlockGrid with another widget.
