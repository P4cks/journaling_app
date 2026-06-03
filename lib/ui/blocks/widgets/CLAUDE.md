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
  row), and the collapsed/empty rendering. **Empty state (no selection):**
  in `BlockMode.editable` it previews ALL options laid out small in a
  `FittedBox`-scaled `Row`, dimmed to 40% opacity ("unfocused carousel",
  GUS-39) so the tile reads as a picker and invites a tap; in
  `BlockMode.readOnly` (or when `options` is empty) it falls back to the
  private em-dash `_CarouselEmptyPlaceholder`. With a selection it centres
  the glyph. `BlockMode.editable`
  delegation to `CollapsibleCarouselBlock<T>` with the
  `AnimatedScale + AnimatedOpacity` focus animation wrapped around the
  caller's raw glyph. Caller responsibilities: compute the title,
  build the raw glyph (`itemBuilder`), and re-encode the picked option
  into block content (`onSelected`). Custom-carousel orphan handling
  stays in `CustomCarouselWidget` — the scaffold only sees a
  resolved, non-empty options list.
- [block_input_limits.dart](block_input_limits.dart) — per-block-type
  input caps + the shared visible counter (GUS-10 rework). Replaces the
  old single hidden `kTextInputMaxChars`.
  - Hard-coded defaults: `kTextBlockMaxChars` (280),
    `kTextSectionMaxChars` (280), `kPromptAnswerMaxChars` (280),
    `kTodoItemMaxChars` (80), `kTodoMaxItems` (8). These are the
    shipped values — the debug menu can override any of them at runtime
    (see `DebugSettings` nullable-int fields). Once a tuned value is
    settled, bake it back into the constant here and drop the override.
  - `BlockInputLimits.of(debugSettings)` resolves the **effective**
    value per limit (`override ?? default`). Call once per build and
    read the field you need. Wrap the editable subtree in
    `ListenableBuilder(listenable: debugSettings)` so live debug tuning
    re-resolves and updates open blocks.
  - `buildCharCounter({onlyWhenFocused})` — a shared
    `TextField.buildCounter` that renders a compact `current/limit`
    counter (labelSmall, `onSurfaceVariant` → `error` at the cap).
    Visible when focused or non-empty; pass `onlyWhenFocused: true` for
    dense layouts (todo rows) so only the active field shows its
    counter.
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
  `options` when promoted into edit mode.

  **Edit-mode is the only way in.** The carousel never auto-expands
  on its own. It opens on the false → true `editing` flip and
  collapses on the true → false flip. Internal tap-to-expand has been
  removed — single-taps on the collapsed view are always inert.

  **Auto-collapse**: when `autoCollapse: true` (default), a 1.5 s
  timer ticks while expanded. The timer resets on every page change
  (steady swipes keep the picker open). When it fires it:
  1. Collapses the carousel.
  2. Releases the pager lock via `onInteractionLockChanged(_, false)`.
  3. Fires `onRequestExitEdit()` so the host clears
     `_editingBlockId` — the in-place edit-mode outline disappears
     in lock-step with the carousel collapsing.

  Both grid and expanded hosts pass `autoCollapse: true` so the
  picker behaves uniformly — collapse to the centred glyph after
  1.5 s of inactivity in either context. The expanded route still
  passes `onRequestExitEdit: null` so the collapse doesn't try to
  clear a non-existent in-place editing flag; the route itself stays
  open and the user can tap the centred glyph to re-engage.

  Props:
  - `blockId` — opaque string used by `onInteractionLockChanged`.
  - `options` — list of T.
  - `selected` — current T or null.
  - `itemBuilder(ctx, option, isSelected)` — carousel page.
  - `collapsedBuilder(ctx, selected)` — collapsed view; should render
    a placeholder when `selected == null`.
  - `onSelected(T)` — called on page change.
  - `onInteractionLockChanged(blockId, locked)` — lifted to
    `JournalPager` to disable the outer horizontal date-swipe while
    expanded.
  - `onRequestExitEdit` — fires in lock-step with the auto-collapse
    so the host can clear `_editingBlockId`. Pass null in the
    expanded route since the picker stays open there.
  - `editing` (default `false`) — externally-driven edit-mode flag.
  - `autoCollapse` (default `true`) — passed `true` from every host
    (grid and expanded). Previously the expanded route passed
    `false`, but the user expectation is uniform 1.5 s collapse
    behaviour in both contexts.
  - `viewportFraction` (0.42), `collapseDelay` (1500 ms),
    `switchDuration` (180 ms) — tunables with sensible defaults.

  Concrete blocks (mood, manual weather, custom carousel) are
  stateless wrappers that decode their content + delegate to this
  widget via `CarouselBlockScaffold<T>`.

## Gotchas

- **The collapse timer fires on expand AND on `onPageChanged`.** Both
  call sites go through `_scheduleCollapse`, which cancels and
  restarts the timer. Don't try to "optimise" by removing one path —
  the expand call is what guarantees auto-collapse for engage-without-swipe.
- **`_controller.jumpToPage(_initialIndex)` runs in a post-frame
  callback after `_expand`.** Without the post-frame deferral, the
  controller isn't attached yet (the PageView is built in the same
  frame as `setState(_expanded = true)`). Don't move it into the
  synchronous handler.
- **`dispose` unconditionally releases the lock** when `_expanded` is
  true. Without this, navigating away mid-expansion would leave
  `JournalPager` stuck in `NeverScrollableScrollPhysics`.
- **`onRequestExitEdit` is intentionally tied to the auto-collapse
  path only.** Calls that collapse via the `editing: true → false`
  transition (host-initiated) do NOT fire it — the host already knows
  it cleared `_editingBlockId`, so re-firing would loop.
- **`AnimatedSwitcher` uses two distinct `ValueKey`s** (`'carousel-collapsed'`
  / `'carousel-expanded'`) so the cross-fade kicks in. Don't drop the
  KeyedSubtree wrappers.
- **`_initialIndex` defaults to 0 when `selected` is null or unknown.**
  Newly-materialized mood/weather blocks have no selection yet, so the
  carousel opens at index 0 (the first option in the list) on first
  engage.

## When to update this file

- A new shared block widget or mixin is added.
- The collapse semantics change (e.g. tap-outside-to-close, swipe-to-dismiss).
- A new tunable is exposed on the carousel.
- The text-content controller mixin grows new lifecycle hooks or its
  abstract surface changes.
- A new per-block input limit is added, or the default values /
  resolver / counter shape in `block_input_limits.dart` change (also
  touch the matching block-type CLAUDE.md and the debug-menu docs in
  `lib/ui/profile/view/CLAUDE.md`).
- The carousel scaffold's surface area grows (new prop, new internal
  rendering rule like a custom empty placeholder).
