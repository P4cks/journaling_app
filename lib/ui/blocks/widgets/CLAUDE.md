# lib/ui/blocks/widgets — Shared block widgets

Reusable widgets consumed by more than one concrete block type — the
collapsible-carousel body shared between the mood and manual-weather
blocks, plus a small title wrapper used by both.

## Files

- [block_with_title.dart](block_with_title.dart) — `BlockWithTitle`.
  Wraps a block body with an optional title row above. When the title
  is null or empty the body is returned unchanged (no padding cost).
  Used by mood/weather carousels to render their per-type-global
  title from `BlockSettings.moodTitle` / `weatherTitle`.
- [collapsible_carousel_block.dart](collapsible_carousel_block.dart) —
  `CollapsibleCarouselBlock<T>` generic StatefulWidget. Renders a
  collapsed centred icon until tapped; tapping expands a horizontal
  `PageView` over `options` and starts an auto-collapse timer
  (default 1500 ms). The timer fires on **expand** AND on every
  `onPageChanged`, so:
  - Tap-and-don't-swipe still auto-collapses after the delay.
  - Steady swipes keep the carousel open until 1.5 s after the last
    interaction.

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
- **`AnimatedSwitcher` uses two distinct `ValueKey`s** (`'carousel-collapsed'`
  / `'carousel-expanded'`) so the cross-fade kicks in. Don't drop the
  KeyedSubtree wrappers.
- **`_initialIndex` defaults to 0 when `selected` is null or unknown.**
  Newly-materialized mood/weather blocks have no selection yet, so the
  carousel opens at index 0 (the first option in the list) on first
  tap.

## When to update this file

- A new shared block widget is added.
- The collapse semantics change (e.g. tap-outside-to-close, swipe-to-dismiss).
- A new tunable is exposed on the carousel.
