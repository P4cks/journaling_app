# lib/ui/blocks/wannado_section — Wanna-do Carousel section

The widget for `SectionKind.wannado` sections (GUS-8/GUS-42/GUS-45,
PRO). Renders one user-created `WannadoDefinition` (a named list) as a
vertical auto-rotating carousel inside a journal entry.

## Files

- [wannado_section_widget.dart](wannado_section_widget.dart) —
  `WannadoSectionWidget` (stateful) + private `_WannadoCard` /
  `_WannadoItemView`. Takes a `String? definitionId` — it grabs
  `blockSettings` from
  [AppDependencies](../../core/widgets/app_dependencies.dart) and
  rebuilds via `ListenableBuilder`.

## Data source — a definition resolved by id, not per-entry content

The section points at a `WannadoDefinition` via `definitionId` (carried
on `LayoutSection` / `EntrySection`); the widget resolves it through
[BlockSettings.findWannadoDefinition](../../../data/services/block_settings.dart)
(definitions persisted in the `settings` box under
`block.wannado.definitions`). The `wannado` `EntrySection` carries **no
blocks** — `materializeLayout` seeds it empty and only the `definitionId`
round-trips. Editing the definition's title/items in Block Settings
notifies `BlockSettings`, so every section referencing it re-renders
immediately. When `definitionId` is `null` (legacy section) or the
definition was deleted, the card shows a placeholder (`missing` flag)
rather than crashing.

## Pure display — no done state

A `WannadoItem` is text only; there is **no** checkbox / done / cross-off
state. A wanna-do is an aspiration the carousel surfaces, identical on
every entry it appears in. This is a deliberate redesign away from a
per-entry checklist — the section is a read-only window onto the global
list. `BlockMode` is therefore **ignored**: editable and read-only days
render the same.

## Rotation

- **Auto** — a `Timer.periodic` (4 s) advances one item. Paused while
  there are 0–1 items (nothing to rotate). Re-armed in the
  `ListenableBuilder` whenever the item count changes (`_syncTimer`).
- **Manual** — the body is a vertical `PageView`; the user can swipe
  up/down. A `ScrollStartNotification` with drag details restarts the
  timer (`_onUserSwipe`) so the auto-advance doesn't immediately yank
  the page away from what the user just swiped to.
- **Looping** — the `PageController` starts at a large virtual base
  page (`_virtualBase = 10000`) and the builder maps
  `index % items.length`, so forward/back rotation never hits an edge.

## Empty state

When the resolved definition has no items the card shows an italic
"Add items to this wanna-do list in Block settings" hint; when no
definition resolves (null id or deleted) it shows "Pick a wanna-do list
for this section" (the `missing` flag distinguishes the two). (`PageView`
physics is `NeverScrollable` for a single item — looping to the same item
would look like a no-op jiggle.)

## Gotchas

- **Renders even though the section has no blocks** — like the
  `divider` case in [journal_pager](../../journal/widgets/journal_pager.dart),
  the `wannado` case must NOT early-return on empty `section.blocks`.
- **Contributes nothing to entry emptiness.** The content lives in the
  definition, so an entry whose only section is wannado is swept at
  midnight if otherwise untouched (see [repositories/CLAUDE.md](../../../data/repositories/CLAUDE.md)).
- **Used as the layout-editor preview too** — `_SectionCard` in the
  layout editor renders this same widget with the section's chosen
  `definitionId` (it'll rotate live there). No per-section item-add
  affordance; the definition is picked in the Add-Section sheet and its
  items are managed in Block Settings.

## When to update this file

- The rotation cadence / interaction model changes.
- A per-item state (done, reorder, etc.) is added — which would also
  reverse the "pure display" decision above.
