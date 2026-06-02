# lib/ui/blocks — Block widgets

The reusable widget layer for journal blocks. **`BlockGrid` lays out
1×1 blocks in a 2-column staggered grid.** It's used by the main
journal screen's swipe pager (inside each section of an entry) and
by the layout editor (WYSIWYG). Editing `BlockGrid` affects both
surfaces; verify both after structural changes.

Full-width text content lives in its own widget — [text_section/](text_section/)
— used by the section-aware journal pager for `SectionKind.text`
sections and stylistically distinct from the `text_block` 1×1 tile
that lives in block-grid sections.

## Files

- [chrome/block_chrome.dart](chrome/block_chrome.dart) — `BlockChrome`,
  replaces the old `post_it_block.dart` and the `PostItBlock` class.
  Pure-theming chrome — wraps any block content in the rounded card
  with rotation / offset / palette colour driven by
  `themeSettings.postItModeEnabled`. **No animation, gesture, or
  interaction logic is gated on the post-it flag** — that's the
  central rewrite invariant. Renders a 2 px accent outline ONLY when
  `host == BlockHostKind.grid && isEditing`; the expanded route reads
  `host: expanded` so the outline is suppressed (the blurred backdrop
  + Hero are the affordance there).

  **Layout scaling: FittedBox + `SizedBox.expand`, applied
  unconditionally.** The block's content is laid out at the natural
  reference size (`kBlockChromeReferenceSize = 160` px) inside a
  `SizedBox` and scaled to fit the chrome's actual constraints via
  `FittedBox(fit: BoxFit.fill, alignment: topLeft)`. The FittedBox is
  itself wrapped in a `SizedBox.expand` so it fills the chrome's full
  constraint rect — without that, the Stack's default `StackFit.loose`
  gives the FittedBox loose constraints and it collapses to its 160 px
  child, leaving the chrome's bottom-right empty in expanded mode.
  In the grid host the constraints already match (~160 px), so the
  FittedBox is a visual no-op. In the expanded host (~330 px) it
  scales up uniformly. During Hero flight every intermediate size
  renders through the same FittedBox path — content never reflows
  mid-morph. `FittedBox` advertises its full constrained size to the
  parent, so pointer hit-tests reach the entire visual area.

  **Padding lives in each block widget, NOT in the chrome.** The 12 px
  inset that separates the rounded-card edge from the block's content
  is added by each block widget INSIDE its own outermost gesture
  wrapper (e.g. `DelayedTapFocus`, the carousel scaffold's
  `GestureDetector`). Putting padding in the chrome made the inset a
  gesture dead-zone — taps in the 12 px ring fell up to the body's
  tap-to-unfocus handler, causing "tapping inconsistent on some parts
  of the block" + keyboard-flash regressions. With padding inside the
  block widget's gesture wrapper, taps anywhere in the 160 px logical
  chrome (incl. the visual inset) reach the block's primary action
  (focus the text, expand the carousel, fire the photo picker, etc.).
- [chrome/block_render_context.dart](chrome/block_render_context.dart) —
  `BlockHostKind` + `BlockEditState` enums and the immutable
  `BlockRenderContext` bundle. Used by `BlockChrome` and the
  expanded route to render the same body widgets in either surface.
- [block_grid.dart](block_grid.dart) — `BlockGrid`. 2-column
  `StaggeredGrid.count` of square 1×1 tiles inside a
  `SingleChildScrollView`. Each tile wraps the block content in a
  `Hero(tag: blockHeroTag(block.id), ...)` so the
  `ExpandedBlockRoute` can morph between the in-grid and expanded
  positions. Drag feedback and delete ghosts are unwrapped from Hero
  (transient same-route widgets — no tag collision). Mount/delete
  animations always run regardless of post-it theming.

  **Drag & drop has been fully refactored to a Notion-style system:**
  - The grid layout is **never mutated during drag** (no ghost tiles, no reflow).
  - A single full-area `DragTarget` handles pointer tracking.
  - The drop position is visualised via an **overlay insertion line**.
  - The dragged tile remains in place but is rendered with reduced opacity.

  Props:
  - `blocks`, `mode` (`BlockMode.readOnly` | `BlockMode.editable`),
    `onBlockChanged` (per-block edit callback),
  - `cardTrailing(block, index)` — optional builder for the top-right affordance,
  - `onReorder(from, to)` — enables long-press drag & drop (Notion-style).
    The callback receives the **final post-remove indices**, so
    handlers should do plain `removeAt(from) + insert(to, item)`. No
    further adjustment.
  - `padding` (default 16),
  - `onJumpToDate(date)` — forwarded to the memory block.
  - `onInteractionLockChanged(blockId, locked)` — forwarded to blocks
    with horizontal carousels (mood, manual weather). `JournalPager`
    wires this through to disable its outer horizontal swipe while
    any inner carousel is expanded, so nested `PageView`s don't fight
    over the drag.
  - `scrollable` (default `true`) — when `true` the grid wraps its
    `StaggeredGrid` in a `SingleChildScrollView` (legacy behavior,
    suitable when `BlockGrid` is the body of a screen). When `false`
    the grid sizes itself to its content with no inner scroll view so
    it can be embedded inside an outer scrolling parent — used by the
    section-aware journal pager (`SectionKind.blockGrid` sections)
    and by the custom-layout editor (stacking multiple block-grid
    sections). Cross-grid drag is NOT supported — each grid's
    `DragTarget` is isolated.
  - `onAddBlock` — optional `VoidCallback` that, when non-null,
    renders an inline `+ Add block` `TextButton.icon` below the
    grid (or by itself when `blocks` is empty). The `DragTarget`
    intentionally wraps the grid only — drops on the button row
    fall through, so the user can't accidentally drop a tile "onto"
    the affordance. The layout editor uses this to host its
    section-level Add button; the journal pager passes `null`.
  - `maxBlocks` — optional `int` cap. Hides the `onAddBlock` button
    once `blocks.length >= maxBlocks`. The grid does **not** reject
    extra blocks supplied via `blocks` — this is purely an
    affordance gate. The view-model is the authority on what's
    allowed (e.g. `LayoutEditorViewModel.addBlockInFixedFour`
    refuses past `fixedFourCapacity`). Used by the layout editor's
    `fixedFourPlusText` body.

- [block_widget.dart](block_widget.dart) — `BlockWidget`. Dispatches on
  `data.type` and constructs the per-type widget. Forwards `editing`
  + `expanded` + `onRequestExitEdit` plumbing where applicable.
  Adding a new `BlockType` requires adding a `case` here.

- [block_mode.dart](block_mode.dart) — `enum BlockMode { readOnly, editable }`.
  Concrete block widgets render differently per mode.

- [block_type_display.dart](block_type_display.dart) — `extension BlockTypeDisplay on BlockType`

  with `label`, `icon` (HugeIcons stroke-rounded; typed `HugeIconData`), `description`, and `sampleData(id:)`.
  Also exposes three getters used by the double-tap engage flow:
  - `usesEditMode` — true for every block that has an interactive
    surface: text / prompt / todo, the three carousel types, photo /
    location / memory. False only for pure-display blocks (quote,
    weather-api), which the grid still skips the double-tap detector
    for.
  - `isActionBlock` — true for photo + memory. When the "expand on
    edit" setting is OFF, `MainJournalScreen._requestBlockEdit` fires
    `firePhotoBlockAction` / `fireMemoryBlockAction` immediately on
    double-tap instead of setting `_editingBlockId` (there's no
    in-place edit-mode UI for one-shot actions). Location is
    intentionally NOT in this set — its "interaction" is long-press
    on the map, which is always available.
  - `usesKeyboardOnEdit` — true for text / prompt / todo. Drives the
    expanded route's two-step dismiss state machine (only keyboard
    blocks need the unfocus-before-pop dance).
  - `isProOnly` — true for every block except `textBlock` + `moodTracker`
    (the free set). Read by the add-block sheet to grey + badge locked
    cells and present the paywall on tap (GUS-19). Pure UI gate — the
    repository/materializer never consult it.


- [widgets/collapsible_carousel_block.dart](widgets/collapsible_carousel_block.dart) —
  `CollapsibleCarouselBlock<T>`. Generic carousel shared between the
  mood / weather / customCarousel blocks. **Never auto-expands on
  null selection** — the user must engage the host block (via
  double-tap) to flip `editing: true`. Auto-collapses after 1.5 s
  unless `autoCollapse: false` is passed (the expanded route does
  this so the picker stays open). On the auto-collapse, fires
  `onRequestExitEdit` so the host clears `_editingBlockId` in
  lock-step with the carousel collapsing. See
  [widgets/CLAUDE.md](widgets/CLAUDE.md).
- [expanded/expanded_block_route.dart](expanded/expanded_block_route.dart) —
  `ExpandedBlockRoute` + private `_ExpandedBlockBody`. Translucent
  `PageRoute<void>` (`opaque: false`) that paints the previous route
  blurred under a `BackdropFilter` and morphs the source tile into a
  square (1:1 aspect) expanded view via `Hero` (tag = `blockHeroTag`).
  Carousels open with the picker already interactive; text / prompt /
  todo open in display state and promote to editing on a tap inside
  the block. Two-step dismiss for keyboard blocks (tap-1 unfocus +
  re-center, tap-2 pop). Action blocks (photo / memory) fire their
  action on a tap inside the route. Text sections render the text
  directly on the blur — no card chrome.
- [text_block/text_block_widget.dart](text_block/text_block_widget.dart)
- [mood_tracker/mood_tracker_widget.dart](mood_tracker/mood_tracker_widget.dart)
- [weather_manual/weather_manual_widget.dart](weather_manual/weather_manual_widget.dart)
- [location_block/location_block_widget.dart](location_block/location_block_widget.dart) —
  `LocationBlockWidget`. flutter_map + OSM tiles; long-press drops a pin.
  See [location_block/CLAUDE.md](location_block/CLAUDE.md).
- [prompt_block/prompt_block_widget.dart](prompt_block/prompt_block_widget.dart)
- [todo_block/todo_block_widget.dart](todo_block/todo_block_widget.dart)
- [quote_block/quote_block_widget.dart](quote_block/quote_block_widget.dart)
- [memory_block/memory_block_widget.dart](memory_block/memory_block_widget.dart)
- [weather_api/weather_api_widget.dart](weather_api/weather_api_widget.dart)
- [photo_block/photo_block_widget.dart](photo_block/photo_block_widget.dart)
- [custom_carousel/custom_carousel_widget.dart](custom_carousel/custom_carousel_widget.dart) —
  `CustomCarouselWidget`. Resolves `definitionId` against the
  `BlockSettings` registry; renders the definition's title + a
  `CollapsibleCarouselBlock<CarouselItem>` over its items, or a
  "Deleted block" placeholder when the lookup fails. See
  [custom_carousel/CLAUDE.md](custom_carousel/CLAUDE.md).

---

## Motion on top of drag-and-drop (post-it era)

Layered on the stable-layout drag system below — none of these
animations affect the grid's RenderBoxes or insertion-index math:

- **Drag**: the source tile's `PostItBlock` receives `isDragging:
  true` while its index matches `_draggingIndex`. That triggers the
  `AnimatedScale` to 1.03 and the `AnimatedContainer` to grow the
  shadow (blur 14 → 24, alpha ×1.6). The `LongPressDraggable.feedback`
  is also a `PostItBlock` with `isDragging: true` for the same look
  on the floating preview.
- **Tap wiggle**: *removed entirely* in the rewrite. The damped ±3°
  rotation that used to fire on every `onPointerDown` no longer fits
  the double-tap-to-engage model — a wiggle on every single tap
  implied "you tapped but nothing happened". If you want it back,
  PR #25's `post_it_block.dart` history has the controller +
  TweenSequence wiring.
- **Add**: each tile is wrapped in `flutter_animate`'s `Animate(...)`
  with a fade + back-easing scale, keyed by `ValueKey('animate-${block.id}')`.
  Effects only run on first mount, so re-orders don't replay them.
  Skipped when `postItModeEnabled` is false (classic mode stays
  still).
- **Delete**: when `didUpdateWidget` notices a block id has gone
  missing, the tile's last-known `Rect` is snapshotted into a
  `_PendingDelete` and rendered as an overlay ghost above the grid.
  The ghost runs `fade → 0` + `scale → 0.7` + `move y +16` (plus a
  small `rotate` when post-it mode is on) for ~320 ms, then removes
  itself in `Animate.onComplete`.
- **Swap (post-drop) is intentionally not animated.** Re-animating
  swapped tiles requires either remounting (loses TextField focus)
  or per-tile `AnimationController` plumbing keyed by block id —
  both have cross-cutting cost. The drop visual is the insertion
  line + the smooth shadow snap from `isDragging: false`; revisit
  if the result feels too abrupt.

## Edit mode (double-tap)

Editing an editable block (text / prompt / todo / mood / weather /
customCarousel) takes a **double-tap** on the tile. Single-taps are
inert. Long-press still triggers reorder via `LongPressDraggable`,
independent of edit mode.

### State model

- `String? editingBlockId` lives on `_MainJournalScreenState` and is
  threaded through `JournalPager → _SectionsBody → BlockGrid →
  BlockWidget → concrete block`. Exactly one block can be in in-place
  edit mode at a time.
- The screen's existing `_editing` keyboard-visibility flag is
  unchanged — it still drives the AppBar's Done collapse and the
  pager's outer lock. The two flags coexist:
  - `_editingBlockId != null` means "this tile is the active in-place
    editor" — affordance is the scale + outline on `PostItBlock`.
  - `_editing == true` means "the keyboard is up". For text / prompt /
    todo blocks both are true while typing; for mood / weather only
    `_editingBlockId` is set.

### Double-tap dispatch

1. `BlockGrid._buildTile` wraps each editable tile in
   `GestureDetector(onDoubleTap: ...)` with
   `behavior: HitTestBehavior.translucent`. The detector is only
   attached for block types where `BlockTypeDisplay.usesEditMode` is
   true AND only while the tile is NOT the active editor — once
   editing, single taps inside the TextField should not wait for the
   double-tap timeout.
2. Text sections in `_SectionsBody` get an analogous detector wired
   to `onRequestTextSectionEdit` (separate callback from grid blocks
   so the screen can set `isTextSection: true` on the route push).
3. The screen's `_requestBlockEdit(block, {isTextSection})` dispatches
   based on `DebugSettings.expandBlockOnEdit`:
   - **ON** (default) → `Navigator.push(ExpandedBlockRoute(...))`.
     `_editingBlockId` stays null; the route owns the edit state.
   - **OFF** → `setState(() => _editingBlockId = block.id)`.

### Inert single-tap inside editable blocks

Concrete editable widgets (`TextBlockWidget`, `TextSectionWidget`,
`PromptBlockWidget`, `TodoBlockWidget`) wrap their interactive
sub-widgets in `AbsorbPointer(absorbing: !editing)`. While not
editing, single-taps that reach the inner widget are swallowed —
the TextField doesn't auto-focus, the carousel doesn't expand.
`CollapsibleCarouselBlock` similarly gates its internal
tap-to-expand on `editing == true`.

### Focusing on activation

`TextContentControllerMixin` (shared by `TextBlockWidget` /
`TextSectionWidget`) owns the `FocusNode`. When subclasses forward
`widget.editing` via the `editing` override, the mixin requests focus
in `didUpdateWidget` whenever the flag flips from false to true
(post-framed to avoid the in-build setState). Same pattern lives
inline in `PromptBlockWidget`. `TodoBlockWidget` doesn't auto-focus
a specific row — the AbsorbPointer drop is enough for the user to tap
the row they want to edit.

### The expanded route

`ExpandedBlockRoute` is a translucent `PageRoute<void>` (`opaque: false`)
that lets the previous route paint through. The body is a Stack of:
1. `BackdropFilter(ImageFilter.blur(σ ≈ 12 * t))` over a tinted color
   layer — t is the route animation value so the blur eases in.
2. A full-screen `GestureDetector(onTap: maybePop)` for the
   tap-outside-to-dismiss affordance. Saves are per-keystroke so a
   dismiss never loses content.
3. The expanded block: `PostItBlock(isEditing: true)` around a
   `BlockWidget(editing: true)`. Keyboard-using blocks sit
   top-aligned with a status-bar inset; others are centered. A no-op
   GestureDetector wraps the block so backdrop taps don't fire for
   gestures on it.
4. Optional "Done" button — only shown when
   `DebugSettings.showExpandedBlockDoneButton` is true (developer
   affordance; tap-outside is the user-facing dismissal).

The route is dismissed by tapping the backdrop, pressing the system
back button, or — in debug mode — the Done button. No Hero animation
is used; the route fades + scales in via the route animation value
read inside the body's `AnimatedBuilder`.

### In-place edit affordance (setting OFF)

`PostItBlock.isEditing` triggers:
- An `AnimatedScale` to 1.05 (composes with drag scale at 1.03 — drag
  wins via the `widget.isDragging ? 1.03 : (widget.isEditing ? 1.05 : 1.0)`
  cascade).
- A 2 px border in `colorScheme.primary` on the card's
  `AnimatedContainer` decoration. Animates in over 180 ms.

`TextSectionWidget` applies its own 2 px primary-color border via an
inner `AnimatedContainer` because it has no `PostItBlock` chrome.

### Action blocks (photo / location / memory)

These keep their existing single-tap behavior. They opt out of the new
flow via `BlockTypeDisplay.usesEditMode == false`. Routing them
through double-tap is a possible follow-up but adds plumbing for
"immediately fire action + exit edit mode" semantics that's out of
scope for this iteration.

## Drag-and-drop (BlockGrid) — how it works

This is now a **stable-layout, overlay-driven reorder system** (similar to Notion).

### Core design principles

- **No grid mutation during drag**
  - Tiles are never inserted/removed/reordered while dragging.
  - Eliminates layout thrash, index drift, and staggered-grid edge cases.

- **Single global DragTarget**
  - The entire grid is wrapped in one `DragTarget`.
  - `onMove` receives pointer updates across the full area.

- **Overlay rendering**
  - A `CustomPainter` draws an insertion line between tiles.
  - Rendered in a `Stack`, so it does not affect layout.

- **Source tile remains in place**
  - Rendered with `Opacity(0.35)` while dragging.
  - Floating preview comes from `LongPressDraggable.feedback`.

---

### Key state in `_BlockGridState`

- `_draggingIndex`
  - Index of the tile being dragged.

- `_insertionIndex`
  - Logical drop position (`0 … blocks.length`)
  - Continuously updated from pointer position.

- `_tileKeys`
  - One `GlobalKey` per tile for layout measurement.

- `_gridKey`
  - Reference box for coordinate conversion.

---

### Insertion index algorithm

1. Convert pointer to grid-local coordinates.
2. Compute tile centres, excluding the dragged tile's slot.
3. If the pointer is above every tile's top → insert at 0
   (`_InsertionEdge.aboveTop`); if below every tile's bottom →
   insert at `n` (`_InsertionEdge.belowBottom`). These short-circuits
   replace the old "closest-in-Y picks an arbitrary edge tile"
   behaviour, which made the insertion line jump unpredictably when
   the user dragged above/below the grid.
4. Otherwise, find row closest in Y from the non-dragged centres.
5. Within that row, find nearest tile in X.
6. Insert:
   - Left half → before
   - Right half → after

---

### Insertion line rendering

- Computed via `_insertionLineInfo()`
- Drawn using `_InsertionLinePainter`
- Rules:
  - Between tiles in the same row → vertical line halfway between
  - Start of row → vertical line 5 px left of the leftmost tile
  - End of row → vertical line 5 px right of the rightmost tile
  - Above row 0 (`_insertionEdge == aboveTop`) → horizontal line 5 px
    above row 0, spanning the row's full width
  - Below the last row (`_insertionEdge == belowBottom`) → horizontal
    line 5 px below the last row
- Includes circular end caps

### Dragged-tile exclusion

`_computeInsertion` excludes the dragged tile from the `centres`
array (sets `centres[_draggingIndex] = null`). Without this, when the
user drags a row-0 tile around row 0, the algorithm sees its own old
slot as one of the candidate "nearest" tiles and anchors the
insertion line on it — most visible when the row has only two tiles
(the source is half the candidates). The dragged tile is still
*painted* at 0.35 opacity, but it doesn't influence the row-Y /
nearest-X heuristics.

---

### Drag lifecycle

- `onDragStarted` → sets `_draggingIndex`
- `onMove` → updates `_insertionIndex`
- `onAccept` → calls `onReorder`
- `onDragEnd` → clears state

---

### Reorder semantics

Insertion-based:

```dart
final to = insertAt > from ? insertAt - 1 : insertAt;
```

---

## Keyboard dismissal — modal edit mode

While a TextField is focused (any block, or the title) the parent
screen enters a "modal editing" state managed by `MainJournalScreen`:

- The screen tracks `_editing` via `WidgetsBindingObserver.didChangeMetrics`
  (reading `platformDispatcher.views.first.viewInsets.bottom > 0`).
  **`MediaQuery.viewInsetsOf(context)` inside the Scaffold body
  returns zero** because Scaffold's `resizeToAvoidBottomInset`
  consumes the bottom insets before they reach descendants —
  detecting via the platform dispatcher is the workaround.
- When `_editing == true`:
  - The AppBar's `actions` collapse to a single `Done` `TextButton`
    that calls `FocusManager.instance.primaryFocus?.unfocus()` — the
    Statistics / Change-layout / Profile actions are removed.
  - `JournalPager.externalLock = true` swaps the `PageView` physics
    to `NeverScrollableScrollPhysics`, so horizontal swipe to adjacent
    entries is disabled.
  - The body-level `GestureDetector(unfocus)` is disabled (onTap:
    null) — the only way out of edit mode is to tap Done.
- When `_editing == false`, all of the above revert to normal.

This applies symmetrically to title edits and block edits — both
raise the keyboard and trigger the same flag. The return key on the
keyboard still inserts newlines in multi-line block TextFields.

AppBar actions (Statistics, ProfileMenuButton, Change-layout) also
call `FocusManager.instance.primaryFocus?.unfocus()` before
navigating AND once more on return — defending against Flutter's
automatic focus restoration when the previously-focused TextField
becomes visible again on pop. In the modal edit state these actions
aren't reachable anyway (they're replaced by Done), but the unfocus
calls remain in place for the non-editing flow.

