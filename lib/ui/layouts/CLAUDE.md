# lib/ui/layouts — Layouts CRUD

The sub-stack under Profile → Layouts. Manages reusable `JournalLayout`
templates: a name, an icon, and an ordered list of `BlockType`s that
new entries are pre-populated from.

```
layouts/
├── layout_icons.dart   curated icon catalogue (top-level, not in a subdir)
├── view/               LayoutsScreen (list) + LayoutEditorScreen
├── view_model/         LayoutsViewModel + LayoutEditorViewModel (+ BlockSlot)
└── widgets/            layout_icon_picker.dart, layout_picker_sheet.dart
```

## Routes

- `/profile/layouts` — list (`LayoutsScreen`)
- `/profile/layouts/new` — editor for a new layout (`LayoutEditorScreen(layoutId: null)`)
- `/profile/layouts/edit/:id` — editor for an existing layout

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

## Reuse: BlockGrid in WYSIWYG mode

The layout editor renders its blocks with the same [BlockGrid](../blocks/CLAUDE.md)
the home preview and editor use — passing `BlockMode.readOnly` plus
`onReorder` (to enable DnD) plus `cardTrailing` (to inject a remove-X
button at the top-right of each tile). The blocks are constructed
ad-hoc from `BlockSlot`s (the VM's lightweight `(id, type)` pair) and
fed to `BlockGrid` as empty `JournalBlockData`s. This is what makes
the layout editor look identical to the entry editor — important so
the user understands the connection.

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
