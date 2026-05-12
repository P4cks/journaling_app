# lib/ui/journal_entry/view_model — Editor view model

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_entry_editor_view_model.dart](journal_entry_editor_view_model.dart) —
  `JournalEntryEditorViewModel extends ChangeNotifier`.

## State

| Field            | Type                  | Purpose                                |
|------------------|-----------------------|----------------------------------------|
| `_repository`    | `JournalRepository`   | For save / get / create.               |
| `_layoutRepository` | `LayoutRepository` | For the layout picker's available list. |
| `_date`          | `DateTime`            | The day this editor is for (immutable). |
| `_entry`         | `JournalEntry?`       | Current state of the entry; mutated locally then persisted. |

The VM **eagerly loads the entry in the constructor** via
`repository.getEntryForDate(date)`. If the day has no entry yet,
`_entry` stays `null` until `createWithLayout`.

## Methods

- `getAvailableLayouts()` — for the picker. Direct passthrough to
  `LayoutRepository.getAll`.
- `createWithLayout(layout)` — creates the entry via the repository and
  assigns to `_entry`. Notifies. Used by the deep-link "Make entry" CTA.
- `updateBlock(updated)` — replaces the matching block by id, bumps
  `lastModified`, saves, notifies. No-op when `_entry == null`.
- `updateTitle(newTitle)` — trim → empty becomes null. Skips notify
  when unchanged. Uses `copyWith(title: ..., clearTitle: normalized == null)`
  to allow round-trip to null. No-op when `_entry == null`.
- `applyLayout(layout)` — **destructive**. Rebuilds `_entry.widgets`
  from the layout's block types (fresh ids), bumps `lastModified`,
  saves, notifies. Caller is responsible for the confirm dialog.

## Implementation details

- Every mutator both **updates `_entry`** and **persists via the
  repository**, in that order. The local update is what the screen
  rebuild reads; the persistence triggers the repository's notify,
  which other VMs (`HomeViewModel`, `JournalEntriesViewModel`) consume.
- The VM **does not subscribe to the repository**. The editor is a
  push-and-pop screen — by the time another flow could mutate the same
  entry, the editor has been popped. (Don't change this without
  thinking through what happens if the resume-sweep deletes the entry
  out from under an open editor.)

## Gotchas

- **Per-keystroke save**. `TextBlockWidget.onChanged` ultimately calls
  `repository.saveJournalEntry` on every character. Hive writes are
  cheap and async, but if you start treating this as a problem,
  introduce a debounce here in the VM — not in the widget.
- **`applyLayout` discards the existing block ids**. New blocks get
  fresh uuids. If a future feature attaches metadata to a block id
  (e.g. server sync), this would orphan it.

## When to update this file

- A new mutator is added (e.g. reorder, delete).
- The save model changes (debounce, explicit save button).
- The VM starts subscribing to the repository.
