# lib/ui/layouts/view — Layouts screens

See [../CLAUDE.md](../CLAUDE.md) for the area overview.

## Files

- [layouts_screen.dart](layouts_screen.dart) — `LayoutsScreen` +
  private `_LayoutIconBadge`. The list at `/profile/layouts`.
  - `ListView.builder` over `vm.layouts`. Each row is a `Dismissible`
    (swipe-end-to-start to delete) wrapping a `ListTile`:
    - Leading: `_LayoutIconBadge` — the layout's chosen icon. Default
      layouts get a stronger background tint and a filled glyph.
    - Title: layout name.
    - Subtitle: `"N block(s)"`.
    - Trailing: a star button (filled when default; tappable on
      non-defaults to set as default; disabled when already default)
      and a chevron.
    - Tap → open the editor at `/profile/layouts/edit/<id>`.
  - FAB → open the editor at `/profile/layouts/new`.
  - `_openEditor` awaits the push and then `vm.refresh()` — because
    `LayoutRepository` doesn't notify, the screen has to refresh
    manually on return.
- [layout_editor_screen.dart](layout_editor_screen.dart) —
  `LayoutEditorScreen` + private `_IconWell`. Editor for one layout.
  - Header row: 56×56 `_IconWell` (tap → `showLayoutIconPicker`) +
    expanded name `TextField`.
  - "Blocks" label + `BlockGrid` (WYSIWYG, see [../CLAUDE.md](../CLAUDE.md)).
    Empty state: "No blocks yet. Tap 'Add block' to start."
  - Bottom: full-width `OutlinedButton.icon` "Add block" → modal
    bottom sheet listing every `BlockType`. Picking one calls
    `vm.addBlock(type)`.
  - AppBar save button is disabled until `vm.canSave` (name not blank).
    Save persists via `vm.save()` and pops.

## Gotchas

- **`Dismissible` requires unique `Key`s.** Currently `ValueKey(layout.id)`.
  Don't reuse layout ids across deletes (uuids handle this).
- **The add-block sheet builds an ad-hoc `BottomSheet` inline** rather
  than living in `widgets/`. If a second screen needs the same picker,
  promote it; for now keeping it inline keeps the call site obvious.
- **`_slotsAsBlockData` constructs empty `JournalBlockData`s on every
  build**. Cheap, but if you start animating tiles, hoist into the VM
  with stable identities.

## When to update this file

- New affordances on the layouts list (e.g. duplicate-layout action).
- The editor gains new fields (e.g. description, color theme).
- The save flow changes (e.g. auto-save instead of explicit save).
