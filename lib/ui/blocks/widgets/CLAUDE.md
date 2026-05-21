# lib/ui/blocks/widgets — Shared block widgets

Reusable widgets and mixins consumed by more than one concrete block
type — the collapsible-carousel body shared between every carousel
block, the carousel scaffold that wraps it, a small title wrapper used
underneath, and a controller-lifecycle mixin shared between the 1×1
text block and the full-width text section.

## Files

- [carousel_block_scaffold.dart](carousel_block_scaffold.dart) —
  `CarouselBlockScaffold<T>`. The shared outer shell for every
  carousel block (mood, manual weather, custom carousel). Owns the
  `BlockWithTitle` wrap (callers pass the resolved title with the
  `carouselTitlesEnabled` gate already applied — `null` collapses the
  row), `BlockMode.readOnly` rendering (centred glyph, or a private
  em-dash placeholder when the selection is null), and `BlockMode.editable`
  delegation to `CollapsibleCarouselBlock<T>` with the
  `AnimatedScale + AnimatedOpacity` focus animation wrapped around the
  caller's raw glyph. Caller responsibilities: compute the title,
  build the raw glyph (`itemBuilder`), and re-encode the picked option
  into block content (`onSelected`). Custom-carousel orphan handling
  stays in `CustomCarouselWidget` — the scaffold only sees a
  resolved, non-empty options list.
- [text_content_controller_mixin.dart](text_content_controller_mixin.dart) —
  `TextContentControllerMixin<T extends StatefulWidget> on State<T>`.
  Owns the `TextEditingController` + `FocusNode` lifecycle for State
  classes whose widget renders a single `TextBlockContent`-backed
  block. Subclasses expose `data`, `onChanged`, and (optionally)
  `editing` (defaults to `false` if the subclass doesn't override).
  The mixin owns:
  - `initState` — build the controller from the current text, build
    a fresh `FocusNode`, and request focus post-frame if `editing`
    is already true at mount (e.g. mounted inside the expanded
    block route).
  - `didUpdateWidget` — swap text only when `data.id` changes
    (never on per-keystroke re-renders); honour `editing` flips by
    requesting / releasing focus on the node post-frame.
  - `dispose` — dispose controller + node.
  - `emitText(String)` — wrap a new string into a fresh
    `JournalBlockData` and forward through `onChanged`.

  Used by both `TextBlockWidget` and `TextSectionWidget` so they
  share one source of truth for the controller dance and the
  double-tap edit-mode focus handoff.
- [block_with_title.dart](block_with_title.dart) — `BlockWithTitle`.
  Wraps a block body with an optional title row above. When the title
  is null or empty the body is returned unchanged (no padding cost).
  Used by every carousel block (mood, manual weather, custom). Callers
  pass `null` when `BlockSettings.carouselTitlesEnabled` is false so
  the row collapses entirely.
- [collapsible_carousel_block.dart](collapsible_carousel_block.dart) —
  `CollapsibleCarouselBlock<T>` generic StatefulWidget. Renders a
  collapsed centred icon and expands a horizontal `PageView` over
  `options` when promoted into edit mode. Tracks an auto-collapse
  timer (default 1500 ms). The timer fires on **expand** AND on
  every `onPageChanged`, so:
  - Tap-and-don't-swipe still auto-collapses after the delay.
  - Steady swipes keep the carousel open until 1.5 s after the last
    interaction.

  **Edit-mode gated expansion**: the internal tap-to-expand only
  fires when `widget.editing == true`. Outside edit mode the
  collapsed view is inert — the outer grid's double-tap detector
  promotes the hosting block into edit mode, which flips `editing`
  to true; `didUpdateWidget` then auto-expands via `_expand()`.
  When `editing` flips back to false the carousel collapses and
  releases the pager lock.

  **Initial-expanded when `selected == null`**: if no selection
  exists at mount time, the widget starts in the expanded state with
  no outer-pager lock. Every item renders at its unselected style
  (none focused) so the user sees the full picker at a glance and
  can swipe to commit, but can still swipe to another journal entry
  before choosing. Auto-collapse is suppressed while `selected` is
  still null — the carousel can't fall back to a placeholder if
  there's nothing to show. Once `onPageChanged` fires (user
  committed) the parent rebuilds with the new `selected`, the next
  scheduled collapse proceeds normally, and the block returns to
  the standard collapsed → tap-to-expand behaviour.

  Props:
  - `blockId` — opaque string used by `onInteractionLockChanged`.
  - `options` — list of T.
  - `selected` — current T or null (legacy empty content).
  - `itemBuilder(ctx, option, isSelected)` — carousel page.
  - `collapsedBuilder(ctx, selected)` — collapsed view; should render
    a placeholder when `selected == null`.
  - `onSelected(T)` — called on page change.
  - `onInteractionLockChanged(blockId, locked)` — lifted to
    `JournalPager` to disable the outer horizontal date-swipe while
    expanded.
  - `editing` (default `false`) — externally-driven edit-mode flag.
    Auto-expands on the false → true transition; collapses on the
    true → false transition. When false, the internal tap-to-expand
    is suppressed so single-taps on a collapsed carousel are inert.
  - `viewportFraction` (0.42), `collapseDelay` (1500 ms),
    `switchDuration` (180 ms) — tunables with sensible defaults.

  Concrete blocks (mood, manual weather) are now stateless wrappers
  that decode their content + delegate to this widget.

## Gotchas

- **The collapse timer fires on expand AND on `onPageChanged`.** Both
  call sites go through `_scheduleCollapse`, which cancels and
  restarts the timer. Don't try to "optimise" by removing one path —
  the expand call is what guarantees auto-collapse for tap-without-swipe.
- **`_controller.jumpToPage(_initialIndex)` runs in a post-frame
  callback after `_expand`.** Without the post-frame deferral, the
  controller isn't attached yet (the PageView is built in the same
  frame as `setState(_expanded = true)`). Don't move it into the
  synchronous tap handler.
- **`dispose` unconditionally releases the lock** when `_expanded` is
  true. Without this, navigating away mid-expansion would leave
  `JournalPager` stuck in `NeverScrollableScrollPhysics`.
- **Initial empty expansion does not acquire the lock.** The block may
  still send a defensive unlock from `dispose()`, but the pager treats
  that as a no-op when the block never locked in the first place.
- **`AnimatedSwitcher` uses two distinct `ValueKey`s** (`'carousel-collapsed'`
  / `'carousel-expanded'`) so the cross-fade kicks in. Don't drop the
  KeyedSubtree wrappers.
- **`_initialIndex` defaults to 0 when `selected` is null or unknown.**
  Newly-materialized mood/weather blocks have no selection yet, so the
  carousel opens at index 0 (the first option in the list) on first
  tap.

## When to update this file

- A new shared block widget or mixin is added.
- The collapse semantics change (e.g. tap-outside-to-close, swipe-to-dismiss).
- A new tunable is exposed on the carousel.
- The text-content controller mixin grows new lifecycle hooks or its
  abstract surface changes.
- The carousel scaffold's surface area grows (new prop, new internal
  rendering rule like a custom empty placeholder).
