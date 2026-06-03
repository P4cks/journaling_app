# lib/ui/layouts/widgets — Layout pickers + section sheets

Four modal bottom sheets and the editor's name title widget. Each
sheet is a stateless top-level function returning the user's pick or
`null` on dismiss.

## Files

- [add_block_sheet.dart](add_block_sheet.dart) —
  `Future<AddBlockResult?> showAddBlockSheet(context, {allowedTypes, title})`
  + sealed `AddBlockResult` (`AddBlockResultBuiltin` / `AddBlockResultCustom`).
  Half-screen sheet built on
  [showDraggableSheet](../../core/widgets/bottom_sheet_scaffold.dart)
  (the shared scaffold owns the drag handle, the title row, and the
  `DraggableScrollableSheet` chrome). The body is the **stateful**
  `_AddBlockSheetBody` (was stateless before GUS-20/GUS-24), top → bottom:
  - **Search field** (`_SearchField`) — a rounded `TextField` with a
    leading search glyph and a trailing clear button (shown via a
    `ValueListenableBuilder` on the controller once non-empty). Live
    filters the active tab's cells: built-in cells match on
    `BlockType.label` / `description`, custom cells on the definition
    `title`. Query is stored trimmed + lower-cased; empty ⇒ no filter.
    When a tab has no matches, `_NoMatchesHint` renders in place of the
    grid. (GUS-20)
  - **Tab switcher** — a 2-segment `SegmentedButton<_BlockTab>`
    (**Default** / **Custom**), shown only when `allowedTypes == null`.
    The two sections render **one-at-a-time** by tab (not stacked as
    before). (GUS-24)
  - **Default tab** (`_buildBuiltinGrid`): a 2-column grid of
    scaled-down built-in block previews (`BlockWidget` in
    `BlockMode.readOnly` with `sampleData`), iterating `BlockType.values`
    minus `_hiddenBlockTypes`.
  - **Custom tab** (`_buildCustomSection`, only when
    `allowedTypes == null`): every `BlockSettings.customCarousels`
    definition as its own tile (live `CustomCarouselWidget` preview
    pointing at the registry), the `ProLimitHint`, plus an
    "Add custom block" `OutlinedButton` that pops the sheet and pushes
    `Routes.newCustomBlock` so the editor stacks on the layout editor.
    The button captures `Navigator` + `GoRouter` before its `await`
    and re-checks the State's `mounted` (lint-clean across the paywall
    async gap).

  Subscribes to `BlockSettings` via `ListenableBuilder`, so a
  definition saved in the editor appears in the Custom tab without
  re-opening the sheet. `_hiddenBlockTypes` excludes `locationBlock`
  (WIP) and `customCarousel` (surfaces only via the per-definition
  tiles). Pass `allowedTypes` to restrict to a subset (used by
  feature-block sections — this hides BOTH the tab switcher and the
  custom section, leaving just the search field + built-in grid; feature
  blocks must be photo/memory). The `title` defaults to "Add block".
  - **Pro gating (GUS-19).** Reads `subscriptionRepository` via
    `AppDependencies`. For free users, built-in cells whose
    `BlockType.isProOnly` is true (everything except text + mood) and
    every custom-carousel cell render **greyed (`_PreviewTile`
    dims + a compact `ProLockBadge`)** rather than being filtered out.
    Tapping a locked cell routes through the shared `_pickBlock` helper:
    it calls `requirePro` and pops with the selection only on a
    successful purchase; unlocked cells pop immediately.
- [add_section_sheet.dart](add_section_sheet.dart) —
  `Future<SectionKind?> showAddSectionSheet(context, {required
  SubscriptionRepository subscriptions})`. Three-tile sheet (Text
  section / Block grid / Feature block), each rendered via the private
  `_SectionTile` (with a `locked` flag). Block-grid sections start
  empty — there is no row picker; the user adds blocks afterwards and
  the grid grows to fit. Feature-block sections also start empty; the
  editor body lets the user pick one photo or memory block via
  `showAddBlockSheet(allowedTypes: …)`. Custom-layout editor uses this
  when the user taps the "Add section" zone at the bottom (passing
  `subscriptions` from `AppDependencies`).
  - **Feature block is Pro-only (GUS-19):** for free users
    (`!kFreeSectionKinds.contains(featureBlock)`) the tile greys +
    badges and tapping presents the paywall, popping
    `SectionKind.featureBlock` only on a successful purchase. Text +
    block-grid are always free.
- [layout_icon_picker.dart](layout_icon_picker.dart) —
  `Future<String?> showLayoutIconPicker(context, {selected})`.
  Modal sheet that shows every icon in [layout_icons.dart](../layout_icons.dart)
  as a 56×56 tile. Returns the chosen `icon.name` (stable identifier
  string carried over from the pre-HugeIcons Phosphor era) or `null`.
  - Tiles that match `selected` get a `primaryContainer` background
    and a thicker primary border; the glyph itself is the same
    stroke-rounded HugeIcons icon as the unselected tiles (the free
    package ships no fill variant).
  - Used by the layout editor's icon AppBar action. Callers may pass
    the returned name (or `null`) straight into `vm.setIconName`.
- [layout_kind_picker_sheet.dart](layout_kind_picker_sheet.dart) —
  `Future<LayoutKind?> showLayoutKindPickerSheet(context)`. Three-tile
  sheet ("Only blocks", "4 blocks + text", "Fully customizable"), each
  with an icon and one-line description. Shown when the user taps the
  FAB on the layouts list. Returns the picked `LayoutKind`; the caller
  pushes the editor with that kind via `Routes.newLayoutFor(kind)`.
  - **All three kinds are free to pick (GUS-19 reversal of BACKLOG
    #96).** Monetization moved off the layout *kind* and onto
    block/section selection, so the `custom` tile is no longer gated —
    `_KindTile` lost its `locked` flag and the sheet no longer takes a
    `subscriptions` param. (Free `blockOnly` layouts are still capped at
    `kFreeMaxBlocksPerLayout`, and the add-block / add-section sheets
    gate individual Pro blocks/sections.)
- [layout_name_title.dart](layout_name_title.dart) — `LayoutNameTitle`.
  Tap-to-edit AppBar title for the editor; commits on submit/blur.
- [layout_picker_sheet.dart](layout_picker_sheet.dart) —
  `Future<JournalLayout?> showLayoutPickerSheet(context, {required layouts, title})`.
  Half-screen sheet built on
  [showDraggableSheet](../../core/widgets/bottom_sheet_scaffold.dart)
  — same UX as `showAddBlockSheet`. Caller provides one `SliverList`
  of `ListTile`s; the scaffold provides the drag handle, the title
  row, and the `DraggableScrollableSheet` chrome. Returns the picked
  layout or `null`. Subtitle text per row summarises the layout via
  its `kind` (e.g. "4 blocks + text" for `fixedFourPlusText`).
  - **Stateless and stand-alone** — both the "Make entry" CTA on the
    main screen and the editor's "Change layout" action share this
    sheet. The editor wraps the result in a destructive-action
    confirm dialog (layout change replaces existing sections); the
    CTA skips the confirm because there's nothing to replace.
  - Returns `null` immediately when `layouts.isEmpty`, without
    showing the sheet — so the caller naturally falls through to
    whatever empty-state behaviour it wants.
  - Long layout lists scroll inside the sheet; the AppBar stays
    visible behind the half-height sheet.

## Gotchas

- **`showLayoutIconPicker` returns the icon NAME**, not a `LayoutIcon`.
  Callers must resolve via `layoutIconFor(name)` when they want the
  glyph. The string is what's persisted in `JournalLayout.iconName`.
- **`showLayoutPickerSheet` is *non-destructive*** — it just returns
  a selection. The destructive-action confirm lives in the editor's
  `_showChangeLayoutSheet`, not here. Don't move it; the home CTA
  must remain confirm-less.

## When to update this file

- A new picker is added (e.g. emoji picker, color picker — though
  the color one already lives in `profile/widgets/swatch_grid_picker.dart`).
- The picker UX changes (e.g. search bar over many layouts).
