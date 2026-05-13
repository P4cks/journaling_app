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

### `BlockSlot`

```dart
class BlockSlot { final String id; final BlockType type; }
```

The editor needs **stable per-slot identities** so reorder/remove can
target the right tile. `BlockSlot` is that lightweight pair. Slots are
converted to sample-content `JournalBlockData`s by the screen — via
`BlockType.sampleData(id: slot.id)` (see
[block_type_display.dart](../../blocks/block_type_display.dart)) — for
`BlockGrid` rendering (matches the "Add block" sheet's preview style),
and to a `List<BlockTemplate>` (with empty configJson) for persistence
(`JournalLayout.blocks`). The sample data is preview-only; the saved
layout never carries it. Block-type-global configuration lives in
[BlockSettings](../../../data/services/block_settings.dart), not in
the slot.

### Construction

- `layoutId == null` → new layout: fresh uuid, empty `_slots`, empty
  name controller, `_isNew = true`.
- otherwise → load via `repository.getById`; if found, hydrate. If
  not found (race: layout deleted between push and build), the
  fallback is the new-layout path (fresh uuid). Not currently guarded
  with a UI error.

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

### Methods

- `addBlock(type)` — append a fresh `BlockSlot`.
- `removeSlot(slotId)` — remove by id. No-op if not found.
- `moveSlot(from, to)` — **insertion-based** semantics matching
  [BlockGrid](../../blocks/CLAUDE.md): `to == from` and `to == from + 1`
  are no-ops; when `to > from`, the effective insert index is
  `to - 1` because the source is removed first.
- `setIconName(name)` — guard against no-op assignment.
- `save()` — guarded by `canSave`. Builds a `JournalLayout` from
  current state, persists via the repository, returns it. The caller
  pops on success.

## Gotchas

- **`nameController` is owned by the VM, not the widget.** This works
  because the widget's `dispose` calls `vm.dispose()` (which disposes
  the controller). Don't try to construct another controller in the
  widget — the listener wiring becomes ambiguous.
- **`moveSlot` mirrors `BlockGrid`'s no-op detection.** If you change
  the DnD semantics, change both — they must agree or tiles will
  shuffle unexpectedly.
- **`save` doesn't notify.** It's a fire-and-pop. The screen pops on
  return, and the list screen will `refresh()` on push-pop.

## When to update this file

- `BlockSlot` grows fields (e.g. a per-slot color hint).
- The editor gains a separate "discard changes?" guard.
- The repository becomes a `ChangeNotifier` (drop the manual
  `refresh()` calls from `LayoutsViewModel`).
