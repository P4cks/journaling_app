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
  `LayoutEditorScreen`. Editor for one layout.
  - AppBar: `LayoutNameTitle` (tap-to-edit) + actions `+ (Add block)`
    and the layout's icon (tap → `showLayoutIconPicker`).
  - Body: the `BlockGrid` (WYSIWYG, see [../CLAUDE.md](../CLAUDE.md))
    fills the body. Empty state: "No blocks yet. Tap + to add a block."
    There is **no** "Blocks" header and no bottom-bar Add button.
  - Adding a block: tap the AppBar `+` → `showAddBlockSheet`
    (see [../widgets/CLAUDE.md](../widgets/CLAUDE.md)) returns the
    chosen `BlockType?`; on non-null, the screen calls
    `vm.addBlock(type)`.
  - **No AppBar save button.** Edits are live to the VM; the screen
    wraps `Scaffold` in `PopScope(canPop: false, ...)` AND registers
    a `NavigationGuard` handler (see
    [../../core/widgets/CLAUDE.md](../../core/widgets/CLAUDE.md))
    for tab switches that `PopScope` can't see.
  - Both paths share `_maybeSaveOnLeave`: if `vm.isDirty` is true the
    handler shows an `AlertDialog` with Cancel / Discard / Save:
    - Discard returns true → caller (pop or tab switch) proceeds.
    - Save calls `vm.save()` and returns true. If the name is blank
      (`!vm.canSave`), shows a SnackBar and returns false (stay on
      screen).
    - Cancel returns false.
  - **Back button** (`_handlePop`): on `canLeave == true`, calls
    `context.pop()` regardless of dirty state — back is an explicit
    "leave this screen".
  - **Tab switch** (`_onTabSwitchAttempt`): on `canLeave == true`,
    pops the editor only if it WAS dirty when the handler started —
    so save/discard puts the user back on the Layouts list, but a
    no-op tab switch leaves the editor mounted for the user to tab
    back to.
  - `vm.save()` re-snapshots the initial state so `isDirty` reads
    false post-save — important for defensive code paths.
  - **Custom-layout sections** render via a per-`SectionKind` switch
    in `_SectionCard.build`:
    - `blockGrid` → `_BlockGridSectionBody` — embedded
      `BlockGrid(scrollable: false)` plus an inline "Add block" button.
    - `text` → `_TextSectionPreview` — a dimmed italic explainer
      (text content lives in the entry, not the layout).
    - `featureBlock` → `_FeatureBlockSectionBody` — full-width
      `AspectRatio(1, ...)` that is either an `_EmptyAddBlockCell` or
      a `_FilledCell`. Tapping opens `showAddBlockSheet(allowedTypes: {photoBlock, memoryBlock})`;
      the X-remove button calls `vm.clearFeatureBlock`. The same
      `_EmptyAddBlockCell` / `_FilledCell` widgets are also used by
      `_FixedFourPlusTextBody`, so they live at the top level of
      `layout_editor_screen.dart`.

## Gotchas

- **`Dismissible` requires unique `Key`s.** Currently `ValueKey(layout.id)`.
  Don't reuse layout ids across deletes (uuids handle this).
- **`_slotsAsBlockData` constructs sample-content `JournalBlockData`s
  on every build** via `BlockType.sampleData(id: slot.id)` so the
  editor's tiles match the "Add block" sheet previews. Cheap, but if
  you start animating tiles, hoist into the VM with stable identities.
  Sample data is preview-only — it never reaches saved entries (the
  VM's `save()` builds `BlockTemplate.create` with empty `configJson`).

## When to update this file

- New affordances on the layouts list (e.g. duplicate-layout action).
- The editor gains new fields (e.g. description, color theme).
- The save flow changes (e.g. auto-save instead of explicit save).
