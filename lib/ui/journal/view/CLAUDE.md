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
│   └── actions: normal: Change-layout (editable + hasEntry),
│                        Statistics icon (push /statistics; dot Badge when
│                          a streak reward is unclaimed — GUS-22),
│                        AppMenuButton (hamburger popup: Settings / Manage Layout / Manage Blocks)
│                editing: Done (unfocus)
├── body: Material(surfaceContainerLow) + SizedBox.expand
│         └── GestureDetector (unfocus-on-tap; disabled when editing)
│              └── inPager (vm.pageIndexForDate(date) != null)
│                   ? JournalPager(vm, modeFor: …, externalLock: editing,
│                                  onMakeEntry: _onMakeEntry)
│                   : editable ? MakeEntryCta : NoEntryReadOnly
└── bottomNavigationBar: CalendarBottomBar(selectedDate, entriesByDay, onDateSelected)
```

## Modal edit mode (`_editing`)

The screen state holds a `_editing` flag, updated from
`WidgetsBindingObserver.didChangeMetrics` (true iff
`platformDispatcher.views.first.viewInsets.bottom > 0`). When true:

- **AppBar `actions`** collapses to a single Done `TextButton` that
  calls `FocusManager.instance.primaryFocus?.unfocus()` AND clears
  `_editingBlockId` if it is set. The normal trio (Change-layout /
  Statistics / AppMenu) is hidden so the user can't navigate away
  mid-edit.
- **`JournalPager.externalLock`** is `true`, which puts the pager on
  `NeverScrollableScrollPhysics` (in addition to the existing inner-
  carousel lock). Horizontal swipe to adjacent entries is disabled.
- **Body `GestureDetector.onTap`** is set to `null`, so tap-outside
  doesn't dismiss either. Only Done can leave the modal state.

The flag is symmetric for block edits and title edits — both raise
the keyboard. **Don't try to read `MediaQuery.viewInsetsOf(context)`
inside the body** — Scaffold's `resizeToAvoidBottomInset` consumes
the bottom insets before they reach descendants, so the value is
zero. Reading via `WidgetsBinding.instance.platformDispatcher` in
`didChangeMetrics` is the workaround.

## Block edit mode (`_editingBlockId`)

Separate from `_editing` (which only tracks keyboard visibility) is
`_editingBlockId` — the id of the block currently in **in-place**
edit mode (active when `DebugSettings.expandBlockOnEdit` is OFF).
The expanded-route variant of editing leaves this null because the
route itself owns the edit state.

`_requestBlockEdit(block, {isTextSection})` is called from the journal
pager when the user double-taps an editable block:

- `expandBlockOnEdit == true` → `Navigator.push(ExpandedBlockRoute(...))`.
  The route paints a blurred backdrop over the entry and positions
  the block top-aligned (keyboard blocks) or centered (others).
- `expandBlockOnEdit == false` → `setState(() => _editingBlockId = block.id)`.
  The matching tile gets a 1.05 scale + accent-color outline (via
  `PostItBlock.isEditing`) and its inner widget becomes interactive.

`_exitInPlaceEdit()` is wired into the body's tap-outside
`GestureDetector` so a tap on empty entry space dismisses in-place
edit mode along with the existing unfocus. See the "Edit mode
(double-tap)" section in [../../blocks/CLAUDE.md](../../blocks/CLAUDE.md)
for the full gesture + propagation contract.

## Edit-mode formula

`editable = _isToday(date) || debug.unlockAllDays`

Same gate as before the merge. Used for two decisions:

1. Whether the title is editable.
2. Whether a past empty day's body is the standalone `MakeEntryCta`
   (editable via `unlockAllDays`) or `NoEntryReadOnly` (read-only).
   Today's empty body is no longer decided here — it's the pager's
   trailing synthetic page (`inPager` is true for today). (GUS-29)
3. Whether each pager page uses `BlockMode.editable` or `BlockMode.readOnly`
   (per-entry — the pager itself can span past + present, so the mode
   is computed per page).

## Actions

- `_onMakeEntry()` — opens the layout picker, calls
  `vm.createWithLayout`. The repository notification fans out to the
  VM, which adds the new entry to its `entries` list; the screen
  rebuilds with the pager pointing at the new entry.
  - Both this and `_showChangeLayoutSheet` pass
    `onManageLayouts: () => context.push(Routes.layouts)` so the
    picker's "Create or edit layouts" footer (GUS-64) jumps to the
    Layouts screen after dismissing the sheet.
- `_showChangeLayoutSheet()` — opens the picker → confirm dialog →
  `vm.applyLayout`. Destructive; always confirms. When no layouts exist
  it shows a "No layouts configured" toast (`showToast`,
  `ToastKind.info`) and returns without opening the picker (GUS-47) —
  otherwise the picker would silently no-op (`showLayoutPickerSheet`
  returns null on an empty list).
- `_openStatistics()` — `context.push(Routes.statistics)`. Back
  returns to `MainJournalScreen` on the same selected date. The
  former `_openEntries` pushed `/entries`; that route still works
  if entered directly, but no AppBar action links to it now.

## Gotchas

- **No Hero animation**. The pre-merge screen used `Hero(journalEntryHeroTag)`
  to morph from a Home preview to the editor; with the screens merged
  there is no separate preview to morph from. Don't reintroduce a
  Hero — it would only confuse the swipe pager's animation.
- **AppBar uses the default `titleSpacing`**. The previous code forced
  `titleSpacing: 0` when an entry existed (to maximise horizontal room
  for the editable title). Material's default 16 px provides better
  breathing room and matches the rest of the app, at the cost of
  slightly less horizontal room for long titles — the title widget
  uses `maxLines: 1` + ellipsis so this is fine in practice.
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
