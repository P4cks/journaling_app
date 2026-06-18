# lib/ui/layouts — Layouts CRUD

The sub-stack under Profile → Layouts. Manages reusable `JournalLayout`
templates: a name, an icon, a `LayoutKind`, and an ordered list of
`LayoutSection`s (each either a text section or a block-grid section
of 1×1 `BlockType`s) that new entries are pre-populated from.

```
layouts/
├── layout_icons.dart   curated icon catalogue (top-level, not in a subdir)
├── entry_to_layout.dart  layoutFromSections() — inverse of materializeLayout (GUS-65)
├── view/               LayoutsScreen (list) + LayoutEditorScreen
├── view_model/         LayoutsViewModel + LayoutEditorViewModel (+ BlockSlot, SectionDraft)
└── widgets/            add_block_sheet, add_section_sheet,
                        layout_icon_picker, layout_kind_picker_sheet,
                        layout_name_title, layout_picker_sheet
```

## Per-day custom layouts (GUS-65, Pro)

A Pro user can build a one-off layout for a single day's entry that is
**never saved to the layout box**. The journal screen
(`MainJournalScreen._openCustomLayoutEditor`) gates on `requirePro`, then
pushes `LayoutEditorScreen(ephemeral: true, seedLayout: …)` via a plain
`Navigator` route (not go_router, so it returns a value). The editor runs
in [ephemeral mode](view/CLAUDE.md) — always `LayoutKind.custom`, no
name/icon chrome, an **Apply** action instead of Save — and returns a
transient `JournalLayout` via `LayoutEditorViewModel.buildEphemeral()`.
The caller materializes it into the day's entry through the existing
`MainJournalViewModel.createWithLayout` (new entry) / `applyLayout`
(existing entry, destructive + confirmed) paths — no VM changes needed.
The seed is the day's current entry (via
[`layoutFromSections`](entry_to_layout.dart), the inverse of
`materializeLayout`) or the default layout for a brand-new day. The
entry point is a Pro-badged "Create a custom layout for this day" footer
row on `showLayoutPickerSheet` (`onCustomLayout`).

## Layout kinds

The three [LayoutKind](../../data/model/layout_kind.dart) values, picked
by the user from a modal sheet when the FAB on the layouts list is
tapped:

- **blockOnly** — one implicit `blockGrid` section. Editor UX is
  identical to the pre-rework editor: a single `BlockGrid` body,
  AppBar `+` to add a block, swipe-remove via the tile's `cardTrailing`
  X. Saving stores one `LayoutSection(kind: blockGrid)` whose
  `blocks` list is the user's slot list.
- **fixedFourPlusText** — locked structure: a block grid (capped at
  4 blocks) + a `text` section. Renders via the same `BlockGrid` the
  custom layout uses, with `maxBlocks: 4` and an inline `onAddBlock`
  Add button that auto-hides at four. Drag-drop, swap-via-tap, and
  remove-X all flow through the grid — visually identical to a
  block-grid section in a journal entry. Save with 0–4 blocks; only
  the filled slots are persisted as `BlockTemplate`s. No add/remove
  sections, no resize, no AppBar `+`. The text section preview uses
  `TextSectionWidget` in `BlockMode.readOnly` (over an empty
  `TextBlockContent`) so it shows the same "No text yet" italic
  placeholder a fresh entry would.
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
  `kLayoutIcons` catalogue + `layoutIconFor(name)`. Each entry has a
  stable `name` (originally the Phosphor identifier string, e.g.
  `"squaresFour"` — kept as-is after the HugeIcons migration so saved
  layouts still resolve), a HugeIcons stroke-rounded `icon`, and a
  human `label`.
  - Names are persisted as plain strings in `JournalLayout.iconName`
    so we don't need a Hive adapter for the underlying icon data.
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
not configure them. Per-type configuration (e.g. the prompt list) is
global and edited from Profile → Block settings, backed
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
`BlockMode.readOnly` plus `onReorder` (DnD), `cardTrailing` (the
remove-X), `onBlockTap` (tap-to-swap-type), and `onAddBlock` (the
inline `+ Add block` button below the grid). For the blockOnly kind
the grid scrolls (`scrollable: true`) and the AppBar `+` adds blocks
because the body shows nothing when empty. For fixedFourPlusText and
custom the grid is embedded in a stacking column with
`scrollable: false`; fixedFourPlusText additionally passes
`maxBlocks: 4` so the Add button auto-hides at the cap. All three
kinds share the same drag-drop code path as the journal pager —
when the journal entry's DnD works, the layout editor's does too.

The blocks are constructed from `BlockSlot`s (the VM's lightweight
`(id, type)` pair) by `_slotPreviewData(slot, blockSettings,
themeSettings)`, which builds a `JournalBlockData` via
`BlockType.sampleData(id: slot.id)` (see
[block_type_display.dart](../blocks/block_type_display.dart)) and
**seeds `BlockVisuals` deterministically from the slot id** against
the live post-it palette. The visuals stay stable across rebuilds and
match what a materialized entry will use — so the editor previews
the entry pixel-for-pixel (including rotation / offset / colour when
post-it mode is on). The sample is preview-only — it never lands in
saved entries (see *Block configuration lives elsewhere* above for
how layouts materialize).

## Gotchas

- **Several Pro gates live in this area; all route through
  `requirePro` / `ProLockBadge` from
  [../core/widgets/pro_gate.dart](../core/widgets/pro_gate.dart).** Each
  reads `subscriptionRepository.isPro` (grabbed from `AppDependencies`
  in `didChangeDependencies`). The customer-info listener flips `isPro`
  before the paywall returns `purchased`, so callers fall through on a
  `true` result. `LayoutRepository` is untouched — every gate lives in
  the UI layer.
  - **#90 — free users limited to 1 layout.**
    `LayoutsScreen._openNewLayoutFlow`: a non-Pro user with ≥1 existing
    layout hits `requirePro` (paywall) before the kind picker; the flow
    continues only on success. The first-launch seeded "Default" layout
    counts as the one free layout, so the gate fires exactly on the 2nd
    attempt.
  - **#96 — REVERSED by GUS-19. `custom` kind is now FREE.**
    `showLayoutKindPickerSheet` no longer takes `subscriptions` and the
    "Fully customizable" tile is no longer greyed/badged — all three
    kinds are free to pick. Monetization moved onto block/section
    selection (below). The `_KindTile` `locked` flag was removed.
  - **#92 — free `blockOnly` layouts capped at
    `kFreeMaxBlocksPerLayout` (6).**
    `LayoutEditorScreen._addBlockBlockOnly` calls `requirePro` once at
    the cap; the AppBar `+` renders greyed with a
    `ProLockBadge(compact: true)` overlay when locked. Only `blockOnly`
    is capped (fixedFourPlusText is hard-capped at 4 regardless of tier).
    `_BlockOnlyBody` shows a `ProLimitHint` ("N of 6 blocks used") above
    the grid for free users.
  - **GUS-32 — free `custom` layouts capped at `kFreeMaxSectionsCustom`
    (3) sections.** `_CustomBody._addSection` calls `requirePro` at the
    cap before opening the add-section sheet; `_CustomBody` shows a
    `ProLimitHint` ("N of 3 sections used") above the add-section zone.
  - **GUS-19/GUS-34 — built-in block gating is now a small Pro set.**
    The add-block sheet greys + badges every `BlockType.isProOnly` cell.
    `isProOnly` derives from `kProOnlyBlockTypes` = `{weatherApi,
    quoteBlock}` (GUS-34) — every other built-in block is now FREE.
    Custom-carousel cells are no longer blanket-locked; instead creating
    a new custom block is capped at `kFreeMaxCustomBlocks` (1) — the shared
    `AddCustomBlockButton` (add-block sheet *and* `block_settings_screen`)
    calls `requirePro` at the cap, with a `ProLimitHint` above it. At the
    cap the button renders greyed with a `ProLockBadge(compact: true)`
    overlay (GUS-40). The
    add-section sheet still gates the **Feature block** tile
    (`featureBlock ∉ kFreeSectionKinds`); text + block-grid stay free.
  - **GUS-22 — streak-reward unlock bypasses a single Pro item's lock.**
    Both the add-block and add-section sheets read
    `AppDependencies.streakRewardSettings`. A Pro block's cell lock
    becomes `!isPro && type.isProOnly && !rewards.isBlockUnlocked(type)`;
    each Pro section lock ANDs `&& !rewards.isSectionUnlocked(kind)`. So
    the one Pro block **or** section the user spent their 7-day streak
    reward token on renders ungated/addable for a free user — every
    other Pro item stays locked. The **count caps** (`kFreeMax*`) are
    intentionally untouched; the reward unlocks *availability* of a
    specific item, not the free-tier quotas. `_CustomBody._addSection`
    passes `rewards:` through to `showAddSectionSheet`.
  - **GUS-40 — free users capped at `kFreeMaxLayouts` (1) saved layout.**
    `LayoutsScreen._openNewLayoutFlow` calls `requirePro` at the cap; the
    list shows a `ProLimitHint` ("1 of 1 layouts used") at the top and the
    new-layout FAB renders greyed with a `ProLockBadge(compact: true)`
    overlay when locked. The screen wraps its body/FAB in a
    `ListenableBuilder` over `subscriptionRepository` so the lock clears
    live on purchase.
  - **GUS-41 — Pro-only layouts lock when a user downgrades.**
    `layoutHasProOnlyFeatures(layout)` (in `pro_gate.dart`) flags any
    layout with a `featureBlock` / `blockTextBody` / `wannado` section,
    a `weatherApi` / `quoteBlock` block, or >1 custom-carousel block.
    `LayoutsScreen._openEditor` runs it for free users and, when true,
    shows `_showProLayoutLockedDialog` (Cancel / Delete layout / Upgrade
    to Pro) **instead of** opening the editor — never auto-deletes. The
    add-block sheet's custom section greys + badges every custom-carousel
    definition past the first (`kFreeMaxCustomBlocks`) for free users
    (see [widgets/CLAUDE.md](widgets/CLAUDE.md)), and the Block-Settings
    wanna-do carousel list caps definitions at `kFreeMaxWannados` for
    free users (see [../profile/view/CLAUDE.md](../profile/view/CLAUDE.md)).
    Old entries keep rendering every block/section — only editing/adding
    is gated.
  See [../subscription/CLAUDE.md](../subscription/CLAUDE.md) and
  [../../data/repositories/CLAUDE.md](../../data/repositories/CLAUDE.md).
- **`LayoutsScreen` refreshes its VM manually on push-pop** because
  `LayoutRepository` is **not** a `ChangeNotifier`. If you change the
  repository to notify, drop the manual `vm.refresh()` after
  `_openEditor`.
- **The "default" star button in the list is disabled for the currently-
  default layout** — tapping a non-default star sets it, but you can't
  un-set a default by tapping; you set another or delete the current
  one (which clears the setting via the repository invariant — see
  [data/repositories/CLAUDE.md](../../data/repositories/CLAUDE.md)).
- **`LayoutEditorViewModel.moveSlot` is plain `removeAt + insert`** —
  `BlockGrid._onAccept` already adjusts the drop index for the post-
  remove list. The pre-fix code did a second adjustment AND dropped
  `to == from + 1` as a no-op, which made forward one-position
  moves silently fail and longer moves off-by-one. Match
  `MainJournalViewModel.reorderBlockInSection` exactly.

## When to update this file

- New icons are added to the catalogue (and document the
  add-vs-remove contract).
- A new layout-level field is added (description, default colour,
  etc.) — propagate through both view models and both Hive adapters.
- The DnD semantics in the editor change.
