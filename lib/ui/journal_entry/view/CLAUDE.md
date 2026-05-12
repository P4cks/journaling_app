# lib/ui/journal_entry/view — Editor screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_entry_editor_screen.dart](journal_entry_editor_screen.dart) —
  `JournalEntryEditorScreen` (StatefulWidget) + `_JournalEntryEditorScreenState`.
  Plus the local `_NoEntryReadOnly` widget for the
  "past-day-with-no-entry" case.

## Construction

- VM constructed in `didChangeDependencies` with the `date` from
  `widget.date` and both repositories from `AppDependencies`.
- Subscribes to `DebugSettings` via an outer `ListenableBuilder` so
  `unlockAllDays` flips the read-only gate live without re-pushing.

## Body structure

```
Scaffold
└── AppBar
    ├── title: hasEntry ? EditorTitle : Text(formatEntryDate(date))
    └── actions: [editable ? "Change layout" : lock-icon]
└── body: Hero(journalEntryHeroTag)
         └── Material(surfaceContainerLow)
              └── SizedBox.expand
                   └── GestureDetector(unfocus-on-tap)
                        └── (hasEntry
                              ? BlockGrid(blocks, mode, onBlockChanged: vm.updateBlock)
                              : editable
                                  ? MakeEntryCta(_onMakeEntry)
                                  : _NoEntryReadOnly())
```

The outer `GestureDetector(HitTestBehavior.opaque)` dismisses the
keyboard when the user taps outside any text-field.

## Actions

- `_showChangeLayoutSheet()` — picker → confirm dialog → `vm.applyLayout`.
  **Confirm because destructive** (replaces blocks).
- `_onMakeEntry()` — picker → `vm.createWithLayout`. **No confirm**
  because nothing to replace.

## Gotchas

- **Editability is `_isToday || debug.unlockAllDays`** — derived from
  `widget.date` and `DateTime.now()` at build time. If the user keeps
  the screen open past midnight, this becomes stale; the
  app-lifecycle resume sweep in `main.dart` doesn't re-trigger this
  build. Real-world impact is small (user has to interact for changes
  to save anyway, and the sweep handles cleanup on resume).
- **`!mounted` guard after every `await`**. The screen could be popped
  while a sheet/dialog is open.

## When to update this file

- The AppBar actions change.
- The body composition changes (e.g. a sidebar, a header strip).
- The editability formula changes.
