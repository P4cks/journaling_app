# lib/ui/journal_entry — Fullscreen entry editor (singular)

The screen behind `/journal/yyyy-mm-dd`. **Singular** — one entry at a
time. Don't confuse with the sibling [`journal_entries/`](../journal_entries/CLAUDE.md)
directory (plural — sectioned list).

```
journal_entry/
├── view/         JournalEntryEditorScreen — wires VM, renders body, AppBar
├── view_model/   JournalEntryEditorViewModel — owns the entry, mutates blocks/title/layout
└── widgets/      EditorTitle (inline-editable AppBar title)
```

## Behaviour

- **Reached from**: tapping the home preview, or tapping a row in the
  entries list. Both use `Routes.journalEntryFor(date)`.
- **Editable when**: the date is today, *or* `DebugSettings.unlockAllDays`
  is on. Past dates are read-only by default (lock icon in the
  AppBar). There is **no explicit edit-toggle** any more — when the
  day is editable and an entry exists, blocks render directly in
  `BlockMode.editable`. The old pencil toggle was dropped in PR #11.
- **Title** — editable inline in the AppBar via `EditorTitle`. Tapping
  the title swaps in a `TextField`; submitting (Enter / blur) commits.
  Empty/whitespace-only commits clear the title back to `null` (date
  fallback).
- **Change layout** — the AppBar action (square-grid icon). Opens the
  layout picker, then a confirm dialog (destructive — replaces existing
  blocks). The home CTA skips the confirm because there's nothing to
  replace.
- **Make entry** — when the editor is reached by deep link to a date
  without an entry (and the date is editable), the body shows
  `MakeEntryCta`. Non-destructive — no confirm.
- **Hero** — the body wraps `BlockGrid` in `Material(color: surfaceContainerLow)`
  with `Hero(tag: journalEntryHeroTag)`. Mirrors the home preview's
  structure so the morph reads as continuous expansion (see
  [home/CLAUDE.md](../home/CLAUDE.md)).
- **Auto-save** — every block edit calls `vm.updateBlock`, which
  `copyWith`s `lastModified` and immediately persists. There is no
  "save" button.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `JournalEntryEditorScreen`
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `JournalEntryEditorViewModel`
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `EditorTitle`

## Gotchas

- **`SizedBox.expand` around the body** — without it, the grey surface
  doesn't reach the bottom of the screen on tall screens, and the Hero
  destination looks like it shrinks during the morph. Root CLAUDE.md
  gotcha.
- **`mode` decision lives in the build method**: `(editable && hasEntry) ? editable : readOnly`.
  The `&& hasEntry` matters — a date with no entry is rendered via the
  `MakeEntryCta`, not an empty editable grid.
- **The "Change layout" action only appears when editable && hasEntry.**
  Past-day editors show a lock icon in the same slot instead.

## When to update this file

- The editability rules change (e.g. a separate "draft" mode for
  future days).
- A new AppBar action is added.
- Auto-save semantics change (debounce, undo).
