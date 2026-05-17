# lib/ui/blocks/custom_carousel — Custom carousel block widget

Renders user-defined carousel "types" — each block instance points at
a [CustomCarouselDefinition](../../../data/model/custom_carousel_definition.dart)
in the `BlockSettings` registry, and the widget reads title + items
from there at render time. Definitions are shared across every block
that references the same id; editing one propagates live to every
existing block.

Content shape (per block):
`{"definitionId": "uuid", "selected": {"kind": "emoji"|"icon", "value": "..."}}`
(both keys omitted when null — orphan / unselected respectively).
Typed wrapper:
[CustomCarouselBlockContent](../../../data/model/block_content/custom_carousel_block_content.dart).

## Files

- [custom_carousel_widget.dart](custom_carousel_widget.dart) —
  `CustomCarouselWidget`. Stateless. Subscribes to `BlockSettings` via
  `ListenableBuilder` so registry edits propagate. Wraps the body in
  [BlockWithTitle](../widgets/block_with_title.dart) using the
  definition's title. Delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)`<CarouselItem>`
  for the carousel mechanic (same UX as mood / weatherManual).
- [carousel_icon_catalogue.dart](carousel_icon_catalogue.dart) —
  `CarouselIcon` + `kCarouselIcons` curated list (~40 Phosphor
  duotone/fill pairs covering nature, activities, food, productivity,
  home, misc). `carouselIconFor(name)` lookup. **Add freely; remove
  cautiously** — removed names orphan items in saved definitions,
  which then render the fallback `question` glyph.

## Modes

- `BlockMode.readOnly` — large filled icon / emoji centred in the
  cell. Em-dash placeholder when no `selected` is stored.
- `BlockMode.editable` — delegates to `CollapsibleCarouselBlock`. The
  selected item is full-scale + filled (for icons); others are
  scaled-down + duotone-dimmed. Tap-to-expand, auto-collapse after
  1.5 s, same as the other carousels.

## Orphan & itemless states

- **Missing `definitionId`** (e.g. the user deleted the definition
  from Block Settings while a layout / entry referenced it) →
  `findCustomCarousel` returns `null` → the widget renders a dimmed
  italic "Deleted block" placeholder. Same behaviour for an empty
  `definition.items` list.
- The sweep treats orphan / no-selection blocks as empty because the
  user can't interact with them, so an otherwise-empty entry whose
  only block is an orphan custom carousel will still get swept at
  midnight. Intentional.

## Item rendering

- `CarouselItemKind.emoji` → `Text(value, fontSize: 56)`.
- `CarouselItemKind.icon` → `AppIcon` resolved via `carouselIconFor`.
  Unknown name → `PhosphorIconsDuotone.question` (fallback, not a
  crash).

## Gotchas

- **`selected` is stored verbatim, NOT by index.** Reordering items
  in the definition leaves existing picks pointing at the right
  value. Don't switch to index-based selection — it would break
  history every time the user reorders.
- **Edits to the registry propagate live to every block.** That's a
  feature (it's why the registry exists), but it means renaming a
  definition's title changes every entry's rendered title. Document
  this in the editor's UI if it surprises users.
- **The icon picker is a curated subset.** Don't try to wire the
  full Phosphor library here — the picker becomes unusable.
- **`onInteractionLockChanged` is forwarded to `CollapsibleCarouselBlock`**
  just like mood / weatherManual, so the outer pager freezes its
  horizontal swipe while the carousel is expanded.

## When to update this file

- A new orphan / fallback state is introduced.
- The carousel mechanic diverges from mood / weatherManual.
- The icon catalogue gains a new category (and document it in the
  Files bullet's category list).
