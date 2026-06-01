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
  `DraggableScrollableSheet` chrome). Body:
  a 2-column grid of scaled-down built-in block previews
  (`BlockWidget` in `BlockMode.readOnly` with `sampleData`), iterating
  `BlockType.values` minus `_hiddenBlockTypes`. Bottom (when
  `allowedTypes == null`): a **Custom blocks** section listing every
  `BlockSettings.customCarousels` definition as its own tile (live
  `CustomCarouselWidget` preview pointing at the registry), plus an
  "Add custom block" `OutlinedButton` that pops the sheet and pushes
  `Routes.newCustomBlock` so the editor stacks on the layout editor.
  Subscribes to `BlockSettings` via `ListenableBuilder`, so a
  definition saved in the editor appears in the section without
  re-opening the sheet. `_hiddenBlockTypes` excludes `locationBlock`
  (WIP) and `customCarousel` (surfaces only via the per-definition
  tiles). Pass `allowedTypes` to restrict to a subset (used by
  feature-block sections — also hides the custom section since feature
  blocks must be photo/memory). The `title` defaults to "Add block".
- [add_section_sheet.dart](add_section_sheet.dart) —
  `Future<SectionKind?> showAddSectionSheet(context)`. Three-tile
  sheet (Text section / Block grid / Feature block). Block-grid
  sections start empty — there is no row picker; the user adds blocks
  afterwards and the grid grows to fit. Feature-block sections also
  start empty; the editor body lets the user pick one photo or memory
  block via `showAddBlockSheet(allowedTypes: …)`. Custom-layout editor
  uses this when the user taps the "Add section" zone at the bottom.
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
  `Future<LayoutKind?> showLayoutKindPickerSheet(context, {required
  SubscriptionRepository subscriptions})`. Three-tile sheet ("Only
  blocks", "4 blocks + text", "Fully customizable"), each with an icon
  and one-line description. Shown when the user taps the FAB on the
  layouts list. Returns the picked `LayoutKind`; the caller pushes the
  editor with that kind via `Routes.newLayoutFor(kind)`.
  - **The "Fully customizable" (`custom`) tile is Pro-only (BACKLOG
    #96).** For free users it renders greyed with a trailing
    `ProLockBadge`; tapping it calls `requirePro(subscriptions)` and
    only pops with `LayoutKind.custom` on a successful purchase
    (otherwise the sheet stays open). Pro users pop immediately. The
    other two kinds are always free. `_KindTile` gained a `locked`
    flag driving the grey + badge.
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
