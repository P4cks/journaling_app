# lib/ui/layouts/view_model — Layouts view models

See [../CLAUDE.md](../CLAUDE.md) for the area overview.

## Files

- [layouts_view_model.dart](layouts_view_model.dart) —
  `LayoutsViewModel extends ChangeNotifier`. Backs the list screen.
- [layout_editor_view_model.dart](layout_editor_view_model.dart) —
  `LayoutEditorViewModel extends ChangeNotifier` + `BlockSlot` value class.
  Backs the editor screen.

## LayoutsViewModel (list)

- `_layouts` and `_defaultId` are re-read from the repository on every
  `refresh()` call.
- `refresh()` is **manually invoked** from the screen after a push-pop
  (because the repo doesn't notify) and after `setDefault` / `delete`.
- `delete(id)` defers to `LayoutRepository.delete`, which also clears
  the default-id setting when the deleted layout was the default —
  see [data/repositories/CLAUDE.md](../../../data/repositories/CLAUDE.md).

## LayoutEditorViewModel (editor)

### `BlockSlot` and `SectionDraft`

```dart
class BlockSlot {
  final String id;
  final BlockType type;
  final String? definitionId; // non-null for customCarousel + habitTracker slots
}
class SectionDraft {
  final String id;
  final SectionKind kind;
  int? rows;             // blockGrid only
  List<BlockSlot> slots; // empty for text sections
}
```

`definitionId` is threaded into `BlockTemplate.configJson` at save
time (`{"definitionId": "..."}`) and pulled back out on load, so
custom-carousel **and habit-tracker** slots round-trip correctly
through Hive without a schema bump.

The editor needs **stable per-slot and per-section identities** so
reorder/remove can target the right tile or section. `BlockSlot` is
the lightweight `(id, type)` pair. `SectionDraft` mirrors the persisted
`LayoutSection` shape but holds mutable `slots` (the editor swaps
the list reference on each change to keep `notifyListeners` cheap).
Slots are converted to sample-content `JournalBlockData`s by the
screen — via `BlockType.sampleData(id: slot.id)` (see
[block_type_display.dart](../../blocks/block_type_display.dart)) — for
`BlockGrid` rendering (matches the "Add block" sheet's preview style),
and to a `List<BlockTemplate>` (with empty configJson) for persistence
(`LayoutSection.blocks`). The sample data is preview-only; the saved
layout never carries it. Block-type-global configuration lives in
[BlockSettings](../../../data/services/block_settings.dart), not in
the slot.

### Construction

- `layoutId == null` → new layout: fresh uuid, `kind = initialKind`
  (defaults to `blockOnly`), `_sections` seeded per kind:
  - `blockOnly` → one empty `blockGrid` section.
  - `fixedFourPlusText` → one `blockGrid(rows: 2)` with four
    `textBlock` slots followed by one `text` section.
  - `custom` → empty sections list — user adds via the tap zone.
- otherwise → load via `repository.getById`; if found, hydrate.
  Kind comes from the persisted layout. If not found (race: layout
  deleted between push and build), the fallback is the new-layout
  path (fresh uuid, default kind). Not currently guarded with a UI
  error.

### State

- `_id` — uuid. Stable for the editor's lifetime, used as the save key.
- `nameController` — `TextEditingController`. Owned by the VM (not the
  widget) because `canSave` depends on its value; the controller's
  listener notifies the VM so the AppBar save button can enable/
  disable live.
- `_iconName` — nullable. `null` means "use the default icon".
- `_slots` — ordered list of `BlockSlot`. Exposed as
  `List.unmodifiable` so callers can't sneak in mutations.
- `_isNew` — drives the "New Layout" vs "Edit Layout" AppBar title.

### Methods (kind-gated)

Common:
- `setIconName(name)` — guard against no-op assignment.
- `save()` — defensively re-checks that the name is non-empty AND
  `nameConflict` is false (returns `null` on either failure). Builds
  a `JournalLayout` (with its `kind` and `sections`) from current
  state, persists via the repository, returns it. The caller pops on
  success.

Name validation:
- `canSave` — `true` when the trimmed name is non-empty AND there is
  no `nameConflict`. The editor screen reads this to enable/disable
  the AppBar save affordance live; the save-on-leave dialog also
  checks it before persisting.
- `nameConflict` — `true` when the trimmed, case-insensitive name
  matches another layout (excluding this one's own id). Driven off
  `LayoutRepository.getAll()` each call (cheap; layout volumes are
  small). The save-on-leave dialog surfaces a SnackBar
  ("A layout with this name already exists") when this fires.

All slot-creating methods (`addBlock`, `addBlockInFixedFour`,
`addBlockInSection`, `replaceSlotType`, `setFeatureBlock`,
`setBlockTextFloatBlock`) take an `AddBlockResult` (the discriminated
return of `showAddBlockSheet`) rather than a raw `BlockType`. Internally
`_slotFromResult` / `_typeAndDefIdFromResult` decode the result into a
slot (`BlockType` + optional `definitionId`) — `AddBlockResultCustom` →
`(customCarousel, id)`, `AddBlockResultHabit` → `(habitTracker, id)`.
`setFeatureBlock` additionally rejects non-built-in results because
feature blocks are restricted to photo / memory.

`setFeatureBlock` fills/swaps a `SectionKind.featureBlock` slot
(photo/memory only). `setBlockTextFloatBlock` fills/swaps a
`SectionKind.blockTextBody` float slot and accepts **any** block type
(GUS-46) — built-in, custom, or habit — via `_slotFromResult`.
`clearFeatureBlock` empties **both** kinds (the set
`_singleBlockSectionKinds`). The `blockTextBody` section's body
`textBlock` is **not** an editor slot; it's materialized fresh by
`JournalRepository.materializeLayout`, so it never appears in
`SectionDraft.slots`.

`blockOnly` (operates on the single implicit section):
- `addBlock(result)` — append a fresh `BlockSlot`.
- `removeSlot(slotId)` — remove by id. No-op if not found.
- `moveSlot(from, to)` — plain `removeAt(from) + insert(to, item)`.
  `BlockGrid._onAccept` already adjusts the drop index for the
  post-remove list, so the VM does *no* further translation. Match
  this exactly with `MainJournalViewModel.reorderBlockInSection`. The
  pre-fix code did a second adjustment (`to > from ? to - 1 : to`)
  and dropped `to == from + 1` as a no-op — that made forward
  one-position moves silently fail and forward multi-position moves
  off-by-one. Don't reintroduce.

`fixedFourPlusText` (capacity hard-capped via
`LayoutEditorViewModel.fixedFourCapacity = 4`):
- `addBlockInFixedFour(type)` — append a slot to the first section's
  slot list. No-op when already at capacity.
- `removeFixedFourSlot(slotId)` — remove a slot from the first
  section's slot list. Remaining filled slots compress to the front;
  the editor pads the visual 2×2 grid with empty placeholders.
- `replaceSlotType(slotId, newType)` — swap a filled slot's
  `BlockType` in place (tap-on-tile in the editor). No `addBlock` /
  `removeSlot` / `moveSlot` / section CRUD is exposed.

Only the filled slots are persisted as `BlockTemplate`s — empty
cells are an editor-only concept. Entries materialized from a kind-B
layout naturally contain only the chosen blocks.

`custom` (full section toolkit):
- `addSection(kind)` — append a `SectionDraft`. Block-grid sections
  start empty (no seeded slots); rows are derived from the slot
  count as the user adds blocks.
- `removeSection(sectionId)` — remove by id.
- `moveSection(from, to)` — straight list reorder (the editor uses
  explicit up/down arrows; the no-op detection from `moveSlot`
  doesn't apply).
- `addBlockInSection(sectionId, type)` / `removeSlotInSection` /
  `moveSlotInSection` — per-section equivalents of the blockOnly
  methods. `addBlockInSection` and `removeSlotInSection` recompute
  the section's `rows` from the slot count
  (`(slots.length / 2).ceil()`). `rows` is purely a renderer hint;
  the BlockGrid sizes itself to its blocks regardless.
  `moveSlotInSection` uses the same plain `removeAt + insert` as
  `moveSlot` — `BlockGrid` already adjusts indices.

## Gotchas

- **`nameController` is owned by the VM, not the widget.** This works
  because the widget's `dispose` calls `vm.dispose()` (which disposes
  the controller). Don't try to construct another controller in the
  widget — the listener wiring becomes ambiguous.
- **`moveSlot` mirrors `MainJournalViewModel.reorderBlockInSection`.**
  Both treat `to` as the final post-remove index — `BlockGrid` does
  the adjustment in `_onAccept`. If you ever change `BlockGrid`'s
  drop semantics, change all three sites in lock-step.
- **`save` doesn't notify.** It's a fire-and-pop. The screen pops on
  return, and the list screen will `refresh()` on push-pop.

## When to update this file

- `BlockSlot` grows fields (e.g. a per-slot color hint).
- The editor gains a separate "discard changes?" guard.
- The repository becomes a `ChangeNotifier` (drop the manual
  `refresh()` calls from `LayoutsViewModel`).
