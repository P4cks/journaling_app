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
  `ListenableBuilder` so registry edits propagate. Handles orphan /
  itemless-definition / preserved-pick branches locally
  (`_DeletedPlaceholder`, raw `Center(_renderItem(preserved, true))`).
  Once a non-null definition with non-empty items resolves, delegates
  to [CarouselBlockScaffold](../widgets/carousel_block_scaffold.dart)`<CarouselItem>`
  with `definition.title` (gated by `BlockSettings.carouselTitlesEnabled`)
  and the local `_renderItem` switch as the `itemBuilder`. The scaffold
  owns the focus animation, the read-only em-dash placeholder for the
  not-yet-picked state, and the `BlockWithTitle` wrap; orphan handling
  intentionally stays here because the scaffold only sees a resolved
  definition.
- [carousel_icon_catalogue.dart](carousel_icon_catalogue.dart) —
  `CarouselIcon` + `kCarouselIcons` curated list (~40 HugeIcons
  stroke-rounded glyphs covering nature, activities, food,
  productivity, home, misc). `carouselIconFor(name)` lookup. **Add
  freely; remove cautiously** — removed names orphan items in saved
  definitions, which then render the fallback `question` glyph.
  Persisted `name` strings carry over from the pre-HugeIcons Phosphor
  era; only the resolved icon data changed.

## Modes

- `BlockMode.readOnly` — large filled icon / emoji centred in the
  cell. Em-dash placeholder when no `selected` is stored.
- `BlockMode.editable` — delegates to `CollapsibleCarouselBlock`.
  With a selection: tap-to-expand, full-scale focused item, others
  scaled down + dimmed, auto-collapse after 1.5 s. **With no
  selection**: starts already-expanded so all items are visible at
  the dimmed style and the user can swipe to commit straight away
  — same always-expanded-when-empty contract as mood / weather.

## Orphan & itemless states

- **Missing definition + no prior pick**: `findCustomCarousel` returns
  `null` and `content.selected` is `null` → renders the dimmed italic
  "Deleted block" placeholder. Same behaviour for an empty
  `definition.items` list.
- **Missing definition + previously-saved pick**: when the user had
  already picked an item before the definition was deleted, the
  widget renders the verbatim pick (centred, locked — no carousel
  since the option list is gone). The point: deleting a definition
  doesn't visually erase what the user logged in past entries.
- The sweep still treats no-selection-with-orphan-definition blocks
  as empty because the user can't interact with them. A block that
  HAS a preserved pick is non-empty and keeps the entry alive.

## Item rendering

- `CarouselItemKind.emoji` → `Text(value, fontSize: 56)`.
- `CarouselItemKind.icon` → `AppIcon` resolved via `carouselIconFor`.
  Unknown name → `HugeIcons.strokeRoundedQuestion` (fallback, not a
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
  full HugeIcons library here — the picker becomes unusable.
- **`onInteractionLockChanged` is forwarded to `CollapsibleCarouselBlock`**
  just like mood / weatherManual, so the outer pager freezes its
  horizontal swipe while the carousel is expanded.

## When to update this file

- A new orphan / fallback state is introduced.
- The carousel mechanic diverges from mood / weatherManual.
- The icon catalogue gains a new category (and document it in the
  Files bullet's category list).
