# lib/ui/layouts/widgets — Layout pickers + section sheets

Four modal bottom sheets and the editor's name title widget. Each
sheet is a stateless top-level function returning the user's pick or
`null` on dismiss.

## Files

- [add_block_sheet.dart](add_block_sheet.dart) —
  `Future<BlockType?> showAddBlockSheet(context)`. Half-screen
  `DraggableScrollableSheet` (initial 0.5, max 0.9) with a 2-column
  `SliverGrid` of scaled-down block previews. Each cell renders the
  real `BlockWidget` in `BlockMode.readOnly` with sample content
  (from `BlockTypeDisplay.sampleData`) wrapped in `AbsorbPointer` +
  `BlockCard`, plus the type's `label` and `description` below. Tap
  pops the chosen `BlockType`. Iterates `BlockType.values`, so new
  block types only need cases in `block_type_display.dart` to appear.
- [add_section_sheet.dart](add_section_sheet.dart) —
  `Future<SectionKind?> showAddSectionSheet(context)`. Two-tile sheet
  (Text section / Block grid). Block-grid sections start empty —
  there is no row picker; the user adds blocks afterwards and the
  grid grows to fit. Custom-layout editor uses this when the user
  taps the "Add section" zone at the bottom.
- [layout_icon_picker.dart](layout_icon_picker.dart) —
  `Future<String?> showLayoutIconPicker(context, {selected})`.
  Modal sheet that shows every icon in [layout_icons.dart](../layout_icons.dart)
  as a 56×56 tile. Returns the chosen `icon.name` (Phosphor identifier
  string) or `null`.
  - Tiles that match `selected` get a `primaryContainer` background
    and a thicker primary border + the fill variant of the glyph.
  - Used by the layout editor's icon AppBar action. Callers may pass
    the returned name (or `null`) straight into `vm.setIconName`.
- [layout_kind_picker_sheet.dart](layout_kind_picker_sheet.dart) —
  `Future<LayoutKind?> showLayoutKindPickerSheet(context)`. Three-tile
  sheet ("Only blocks", "4 blocks + text", "Fully customizable"),
  each with an icon and one-line description. Shown when the user
  taps the FAB on the layouts list. Returns the picked `LayoutKind`;
  the caller pushes the editor with that kind via
  `Routes.newLayoutFor(kind)`.
- [layout_name_title.dart](layout_name_title.dart) — `LayoutNameTitle`.
  Tap-to-edit AppBar title for the editor; commits on submit/blur.
- [layout_picker_sheet.dart](layout_picker_sheet.dart) —
  `Future<JournalLayout?> showLayoutPickerSheet(context, {required layouts, title})`.
  Modal sheet listing every layout the user has. Returns the picked
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
