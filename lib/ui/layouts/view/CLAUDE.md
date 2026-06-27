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
    - Trailing (GUS-28): a `ProLockBadge` "Pro" chip (GUS-72) leads when
      `!subs.isPro && layoutHasProOnlyFeatures(layout)` (a free user
      viewing a layout built with Pro-only sections/blocks — Pro users
      get no badge since every layout is editable for them); then the
      default row shows a `LayoutDefaultChip` ("★ Default" pill) while
      non-default rows show an explicit `TextButton.icon` "Set default"
      that calls `vm.setDefault`. A chevron follows. (The chip replaced
      the old bare star `IconButton` whose meaning relied on a tooltip.)
    - Tap → open the editor at `/profile/layouts/edit/<id>`.
  - FAB → open the editor at `/profile/layouts/new`.
  - `_openEditor` awaits the push and then `vm.refresh()` — because
    `LayoutRepository` doesn't notify, the screen has to refresh
    manually on return.
- [layout_editor_screen.dart](layout_editor_screen.dart) —
  `LayoutEditorScreen`. Editor for one layout.
  - **Ephemeral mode (GUS-65).** `LayoutEditorScreen(ephemeral: true,
    seedLayout: …)` runs the editor as a per-day custom-layout builder
    (always `LayoutKind.custom` → `_CustomBody`). The AppBar shows a
    plain "Customize this day" title (no `LayoutNameTitle`/icon action)
    and an **Apply** action (`_applyEphemeral`) that pops
    `vm.buildEphemeral()` via `Navigator.pop` (the screen is pushed with
    a `MaterialPageRoute`, not go_router, so it returns a value). Back
    discards (`_confirmDiscardEphemeral` prompts when `vm.isDirty`) and
    pops `null` — it is never saved to the layout box. See
    [../CLAUDE.md](../CLAUDE.md) "Per-day custom layouts".
  - AppBar (normal mode): `LayoutNameTitle` (tap-to-edit) + actions
    `+ (Add block)`, the layout's icon (tap → `showLayoutIconPicker`),
    and a trailing `Save` `TextButton` (GUS-62).
  - Body: the `BlockGrid` (WYSIWYG, see [../CLAUDE.md](../CLAUDE.md))
    fills the body. Empty state: "No blocks yet. Tap + to add a block."
    There is **no** "Blocks" header and no bottom-bar Add button.
  - Adding a block: tap the AppBar `+` → `showAddBlockSheet`
    (see [../widgets/CLAUDE.md](../widgets/CLAUDE.md)) returns the
    chosen `BlockType?`; on non-null, the screen calls
    `vm.addBlock(type)`.
  - **Dedicated `Save` button** (GUS-62, `_save`): validates the name
    the same way `_maybeSaveOnLeave` does (empty → "Add a name to save"
    toast; duplicate → "A layout with this name already exists" toast;
    both keep the user on the editor), then `vm.save()` + a success
    toast + `context.pop()` back to the Layouts list. `context.pop()`
    force-pops, so it bypasses the `PopScope` guard — nothing is unsaved
    after a successful save. Always enabled (an unchanged save is a
    harmless re-write); feedback comes from the on-tap validation, not a
    greyed-out state.
  - Edits are otherwise live to the VM; the screen wraps `Scaffold` in
    `PopScope(canPop: false, ...)` so a Back press routes through
    `_handlePop` → `_maybeSaveOnLeave` (the save-on-leave safety net).
    There are no tab switches to guard against anymore (the bottom-nav
    app-shell is gone — see
    [../../core/widgets/CLAUDE.md](../../core/widgets/CLAUDE.md)).
  - The Back press routes through `_maybeSaveOnLeave`: if `vm.isDirty`
    is true the handler **validates the name first, then prompts**. It computes
    `canSave` (name non-blank and `!nameConflict`) before building the
    `AlertDialog`, so the dialog adapts:
    - Saveable → a Cancel / Discard / Save dialog, body "Save your
      changes to this layout before leaving?". Save calls `vm.save()`
      and returns true. Discard returns true → caller proceeds. Cancel
      returns false.
    - Not saveable (blank or duplicate name) → fires an error `showToast`
      ("Add a name to save" / "A layout with this name already exists")
      and **returns false with no dialog** — the user stays on the editor
      to fix the name. There's no "discard from the unsaveable state"
      prompt.
  - **Back button** (`_handlePop`): on `canLeave == true`, calls
    `context.pop()` regardless of dirty state — back is an explicit
    "leave this screen".
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
  - **Custom-layout sections** render in a `ReorderableListView` inside
    `_CustomBody` (drag-and-drop reorder via each card's header drag
    handle — `onReorderItem: vm.moveSection`, `buildDefaultDragHandles:
    false`; no up/down buttons). `_SectionCard` has **no card chrome**
    (the old `surfaceContainerLow` fill + `outlineVariant` border are
    gone) so block previews look like real entry content; it keeps only
    a slim quiet header (leading `ReorderableDragStartListener` drag
    handle, faded type label, trailing remove-X) and a hairline
    `Divider` between sections. The body still routes via the
    per-`SectionKind` switch in `_SectionCard.build`:
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
      `layout_editor_screen.dart`). Tapping a cell opens the **general**
      `showAddBlockSheet(context)` (any built-in / custom / habit block —
      GUS-67, was photo/memory only) → `vm.setSingleBlock`; the X-remove
      calls `vm.clearSingleBlock`. `_EmptyAddBlockCell` is no longer used
      by `_FixedFourPlusTextBody` (which now uses `BlockGrid.onAddBlock`) —
      the two single-block sections (feature-block + block-text-body) are
      the only callers.
    - `header` → `_HeaderSectionPreview` — a `HeaderSectionWidget` in
      `BlockMode.readOnly` over an empty `TextBlockContent` (mirrors
      `_TextSectionPreview`; shows the italic "Heading" placeholder).
      No add affordance — the heading text is entered per-entry. (GUS-6)
    - `divider` → a plain padded `Divider`. No add affordance. (GUS-7)
    - `blockTextBody` → `_BlockTextSectionBody` — a `Row` of the
      float-block picker (`_EmptyAddBlockCell` / `_FilledCell`) left of a
      read-only `_TextSectionPreview`, hinting the materialized entry's
      float arrangement. The block is sized to exactly one tile of a
      2-column `BlockGrid` — `((maxWidth - 44) / 2).clamp(120, 220)` via
      a `LayoutBuilder` hoisted ABOVE the padding (so `maxWidth` is the
      full section width) — matching a "normal" grid block rather than
      a fixed 120px square or the old `* 0.42` proportion. The picker
      uses the **general** `showAddBlockSheet(context)` (any built-in /
      custom / habit block — GUS-46, was photo/memory only) →
      `vm.setSingleBlock` (accepts any `AddBlockResult`, shared with
      `featureBlock`); the X-remove calls `vm.clearSingleBlock`. The text
      block is entered per-entry (not an editor slot). (GUS-9)
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
  "Deleted block" placeholder. **Habit slots are threaded the same
  way** (GUS-73): a `habitTracker` slot with a `definitionId` builds
  `HabitBlockContent(definitionId:, completed: true)` so the preview
  shows the habit's real title rather than `sampleData`'s generic
  title-less checkmark. **Visuals are seeded** from
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
  **Section** reorder (custom kind) instead flows from a
  `ReorderableListView`'s `onReorderItem: vm.moveSection` — that
  callback pre-adjusts `newIndex`, and `moveSection` is itself a plain
  `removeAt + insert`, so they compose cleanly. An explicit
  `ReorderableDragStartListener` drag handle (with
  `buildDefaultDragHandles: false`) is required so the section drag
  doesn't clash with a block-grid section's long-press block drag.

## When to update this file

- New affordances on the layouts list (e.g. duplicate-layout action).
- The editor gains new fields (e.g. description, color theme).
- The save flow changes (e.g. auto-save instead of explicit save).
