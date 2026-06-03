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
    - Trailing (GUS-28): the default row shows a `LayoutDefaultChip`
      ("★ Default" pill); non-default rows show an explicit
      `TextButton.icon` "Set default" that calls `vm.setDefault`. A
      chevron follows. (Replaced the old bare star `IconButton` whose
      meaning relied on a tooltip.)
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
  - **All three layout kinds share the same `BlockGrid` for slot
    rendering, drag-drop, and the inline "Add block" affordance.**
    The grid handles drag-drop (forwarding `from -> to` to
    `vm.moveSlot` / `vm.moveSlotInSection` with already-adjusted post-
    remove indices), hosts an inline Add button via `onAddBlock`, and
    caps via `maxBlocks` (see [../../blocks/CLAUDE.md](../../blocks/CLAUDE.md)
    "Add-block affordance"). Per-kind specifics:
    - `LayoutKind.blockOnly` → `_BlockOnlyBody`. The AppBar still
      hosts the `+ (Add block)` action because the body renders no
      affordance when empty (and we want the user to discover the
      action from the chrome). The grid is `scrollable: true` and
      fills the screen. **Free users are capped at
      `kFreeMaxBlocksPerLayout` (6) blocks (BACKLOG #92):**
      `_addBlockBlockOnly` calls `requirePro` before opening the
      add-block sheet once at the cap, and the AppBar `+` renders
      greyed with a `ProLockBadge(compact: true)` overlay when
      `blockOnlyLocked` (non-Pro && slot count ≥ 6).
    - `LayoutKind.fixedFourPlusText` → `_FixedFourPlusTextBody`.
      A `BlockGrid(scrollable: false, maxBlocks: 4, onAddBlock: …)`
      followed by `_TextSectionPreview`. The 2×2 placeholder grid
      from before the consolidation is gone — the grid grows tile-
      by-tile as the user adds blocks, and the inline Add button
      auto-hides at four. Drag-drop just works (insertion-line
      visual + index handoff identical to the journal entry pager).
    - `LayoutKind.custom` → `_CustomBody` + `_SectionCard`. Each
      `SectionKind.blockGrid` section renders a
      `BlockGrid(scrollable: false, onAddBlock: …)`. Empty sections
      show only the inline Add button — no separate empty-state
      branch.
  - **Custom-layout sections** still route via the per-`SectionKind`
    switch in `_SectionCard.build`:
    - `blockGrid` → `_BlockGridSectionBody` — `BlockGrid` with the
      Add button baked in.
    - `text` → `_TextSectionPreview` — a `TextSectionWidget` in
      `BlockMode.readOnly` over an empty `TextBlockContent`. That
      matches what a fresh entry shows ("No text yet" in italic) so
      the editor mirrors the materialized entry's empty state. No
      separate styled card.
    - `featureBlock` → `_FeatureBlockSectionBody` — full-width
      `AspectRatio(1, ...)` that is either an `_EmptyAddBlockCell` or
      a `_FilledCell` (both live at the top level of
      `layout_editor_screen.dart`). Tapping a filled cell opens
      `showAddBlockSheet(allowedTypes: {photoBlock, memoryBlock})`;
      the X-remove calls `vm.clearFeatureBlock`. `_EmptyAddBlockCell`
      is no longer used by `_FixedFourPlusTextBody` (which now uses
      `BlockGrid.onAddBlock`) — feature-block is the only caller.
    - `header` → `_HeaderSectionPreview` — a `HeaderSectionWidget` in
      `BlockMode.readOnly` over an empty `TextBlockContent` (mirrors
      `_TextSectionPreview`; shows the italic "Heading" placeholder).
      No add affordance — the heading text is entered per-entry. (GUS-6)
    - `divider` → a plain padded `Divider`. No add affordance. (GUS-7)
    - `blockTextBody` → `_BlockTextSectionBody` — a `Row` of the
      float-block picker (`_EmptyAddBlockCell` / `_FilledCell`, same
      slot machinery as `_FeatureBlockSectionBody`) left of a read-only
      `_TextSectionPreview`, hinting the materialized entry's float
      arrangement. The block is sized to exactly one tile of a 2-column
      `BlockGrid` — `((maxWidth - 44) / 2).clamp(120, 220)` via a
      `LayoutBuilder` hoisted ABOVE the padding (so `maxWidth` is the
      full section width) — matching a "normal" grid block rather than
      a fixed 120px square or the old `* 0.42` proportion. The picker uses
      `showAddBlockSheet(allowedTypes: featureBlockAllowedTypes)` →
      `vm.setFeatureBlock`; the X-remove calls `vm.clearFeatureBlock`
      (both generalized to accept this kind). The text block is entered
      per-entry (not an editor slot). (GUS-9)
    - `wannado` → a `WannadoSectionWidget` preview (the same widget the
      journal pager renders). It self-fetches the **global** wanna-do
      list off `AppDependencies.blockSettings` and rotates live in the
      editor. No add affordance — items are managed in Block settings,
      not per-section. (GUS-8)

## Gotchas

- **`Dismissible` requires unique `Key`s.** Currently `ValueKey(layout.id)`.
  Don't reuse layout ids across deletes (uuids handle this).
- **`_slotPreviewData(slot, settings, theme)`** is the single helper
  that turns a `BlockSlot` into the `JournalBlockData` the BlockGrid
  renders. Built-in types fall through to `BlockType.sampleData`;
  custom-carousel slots thread their `definitionId` (and pre-select
  the first item of the registry definition, if any) so the preview
  resolves the real title + items instead of falling through to the
  "Deleted block" placeholder. **Visuals are seeded** from
  `Random(slot.id.hashCode)` against `themeSettings.postItPalette`
  so the editor mirrors what a materialized entry will look like —
  same rotation/offset/colour. The seed is deterministic, so visuals
  stay stable across rebuilds (rebuilds happen on every keystroke in
  the name field). When post-it mode is off, `BlockChrome` ignores
  the rotation/offset/colour fields, so passing visuals is harmless.
  Used at every slot-render site — don't reintroduce raw
  `sampleData(id:)` calls.
- **Sample-content `JournalBlockData`s are constructed on every build.**
  Cheap, but if you start animating tiles, hoist into the VM with stable identities.
  Sample data is preview-only — it never reaches saved entries (the
  VM's `save()` builds `BlockTemplate.create` with empty `configJson`).
- **Reorder semantics match `MainJournalViewModel.reorderBlockInSection`.**
  `BlockGrid._onAccept` already adjusts the drop index for the
  post-remove list, so `LayoutEditorViewModel.moveSlot` /
  `moveSlotInSection` are plain `removeAt + insert`. The pre-fix
  code did a second adjustment and dropped `to == from + 1` as a
  no-op, which made forward moves of one position silently fail and
  forward moves of more than one off-by-one. See
  [../view_model/CLAUDE.md](../view_model/CLAUDE.md) "Move semantics".

## When to update this file

- New affordances on the layouts list (e.g. duplicate-layout action).
- The editor gains new fields (e.g. description, color theme).
- The save flow changes (e.g. auto-save instead of explicit save).
