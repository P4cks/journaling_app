# lib/ui/layouts — Layouts CRUD

The sub-stack under Profile → Layouts. Manages reusable `JournalLayout`
templates: a name, an icon, a `LayoutKind`, and an ordered list of
`LayoutSection`s (each either a text section or a block-grid section
of 1×1 `BlockType`s) that new entries are pre-populated from.

```
layouts/
├── layout_icons.dart   curated icon catalogue (top-level, not in a subdir)
├── view/               LayoutsScreen (list) + LayoutEditorScreen
├── view_model/         LayoutsViewModel + LayoutEditorViewModel (+ BlockSlot, SectionDraft)
└── widgets/            add_block_sheet, add_section_sheet,
                        layout_icon_picker, layout_kind_picker_sheet,
                        layout_name_title, layout_picker_sheet
```

## Layout kinds

The three [LayoutKind](../../data/model/layout_kind.dart) values, picked
by the user from a modal sheet when the FAB on the layouts list is
tapped:

- **blockOnly** — one implicit `blockGrid` section. Editor UX is
  identical to the pre-rework editor: a single `BlockGrid` body,
  AppBar `+` to add a block, swipe-remove via the tile's `cardTrailing`
  X. Saving stores one `LayoutSection(kind: blockGrid)` whose
  `blocks` list is the user's slot list.
- **fixedFourPlusText** — locked structure: a 2×2 cell grid + a
  `text` section. Cells start empty; each empty cell shows a
  `+ Add block` placeholder. Tapping a placeholder opens the
  add-block sheet and fills the cell; filled cells show the type's
  read-only sample with a small X to remove (tapping a filled tile
  swaps its type via the same add-block sheet). Filled cells
  **compress to the front** — deleting the second cell of three
  filled leaves `[filled, filled, empty, empty]`. The user can save
  with anywhere from 0 to 4 filled cells. **Only the filled cells
  are persisted as `BlockTemplate`s, so entries created from this
  layout only render the actually-chosen blocks** — empty cells
  never appear in the rendered entry. No add/remove sections, no
  resize. No AppBar `+`.
- **custom** — fully editable. The editor renders a vertical stack
  of section cards. Each card has up/down/delete affordances; for
  block-grid sections an inline "Add block" button (the grid grows
  to fit added blocks — no row picker). Below the last section a
  dashed "Add section" tap zone opens [add_section_sheet.dart](widgets/add_section_sheet.dart)
  to append a text or block-grid section. New block-grid sections
  start empty. No AppBar `+` — section creation happens at the tap
  zone.

## Routes

- `/layouts` — list (`LayoutsScreen`)
- `/layouts/new?kind=<name>` — editor for a new layout
  (`LayoutEditorScreen(layoutId: null, initialKind: parsed)`).
  The `kind` query param carries the `LayoutKind.name` chosen from
  the FAB picker; missing/invalid → falls back to `blockOnly`.
  Built via `Routes.newLayoutFor(kind)`.
- `/layouts/edit/:id` — editor for an existing layout (kind is loaded
  from the persisted `JournalLayout`)

All three live inside the Profile branch so the bottom nav stays
visible while editing. See [routing/CLAUDE.md](../../routing/CLAUDE.md).

## Files

- [layout_icons.dart](layout_icons.dart) — `LayoutIcon` class +
  `const kLayoutIcons` catalogue + `layoutIconFor(name)`. Each entry
  has a stable `name` (the Phosphor identifier string, e.g.
  `"squaresFour"`), a duotone glyph, a fill glyph, and a human label.
  - Names are persisted as plain strings in `JournalLayout.iconName`
    so we don't need a Hive adapter for `IconData`.
  - `kDefaultLayoutIconName = 'squaresFour'`.
  - `layoutIconFor(null)` and unknown names both fall back to the
    default icon — safe to call with values written by an older app
    version where an icon was later removed from the catalogue.
  - **Appending** new entries is always safe. **Removing** one orphans
    saved layouts that used it; they fall back to the default icon
    (harmless, but consider leaving deprecated entries in place if
    you don't want a visual reset for existing users).

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `LayoutsScreen`, `LayoutEditorScreen`
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `LayoutsViewModel`, `LayoutEditorViewModel` (+ `BlockSlot`)
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `showLayoutIconPicker`, `showLayoutPickerSheet`

## Block configuration lives elsewhere

The layout editor only chooses **which** block types appear; it does
not configure them. Per-type configuration (e.g. prompt list, text
char limit) is global and edited from Profile → Block settings, backed
by [BlockSettings](../../data/services/block_settings.dart). When an
entry is materialized from a layout (see
[data/repositories/CLAUDE.md](../../data/repositories/CLAUDE.md)),
prompt blocks have their prompt baked in from the global list at that
moment; other blocks read their settings live at render time.

Per-section configuration (rows for blockGrid) lives on
`LayoutSection`. The `BlockTemplate.configJson` field nested inside a
section's `blocks` list is currently always `'{}'` — kept around so
per-template overrides can be reintroduced later without another Hive
schema bump.

## Reuse: BlockGrid in WYSIWYG mode

The layout editor renders its block-grid sections with the same
[BlockGrid](../blocks/CLAUDE.md) the journal pager uses — passing
`BlockMode.readOnly` plus `onReorder` (to enable DnD) plus
`cardTrailing` (to inject a remove-X button at the top-right of each
tile). For the blockOnly kind the grid scrolls (default `scrollable:
true`); for fixedFourPlusText and custom the grid is embedded in a
stacking column and uses `scrollable: false`. The blocks are
constructed ad-hoc from `BlockSlot`s (the VM's lightweight `(id, type)`
pair) via `BlockType.sampleData(id: slot.id)` (see
[block_type_display.dart](../blocks/block_type_display.dart)), so each
tile renders the same rich, sample-content placeholder shown in the
"Add block" sheet. The sample is preview-only — it never lands in
saved entries (see *Block configuration lives elsewhere* above for
how layouts materialize). This is what makes the layout editor look
identical to the entry editor and the picker — important so the user
understands the connection.

## Gotchas

- **`LayoutsScreen` refreshes its VM manually on push-pop** because
  `LayoutRepository` is **not** a `ChangeNotifier`. If you change the
  repository to notify, drop the manual `vm.refresh()` after
  `_openEditor`.
- **The "default" star button in the list is disabled for the currently-
  default layout** — tapping a non-default star sets it, but you can't
  un-set a default by tapping; you set another or delete the current
  one (which clears the setting via the repository invariant — see
  [data/repositories/CLAUDE.md](../../data/repositories/CLAUDE.md)).
- **`LayoutEditorViewModel.moveSlot` translates insert-before semantics
  into list indices**: when moving forward, `to` becomes `to - 1`
  after the source is removed. This matches `BlockGrid`'s
  insertion-based DnD; don't change without also reviewing the grid.

## When to update this file

- New icons are added to the catalogue (and document the
  add-vs-remove contract).
- A new layout-level field is added (description, default colour,
  etc.) — propagate through both view models and both Hive adapters.
- The DnD semantics in the editor change.
