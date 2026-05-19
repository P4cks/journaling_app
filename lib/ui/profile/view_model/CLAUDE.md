# lib/ui/profile/view_model — Profile-area view models

See [../CLAUDE.md](../CLAUDE.md) for the area overview.

## Files

- [block_settings_view_model.dart](block_settings_view_model.dart) —
  `BlockSettingsViewModel extends ChangeNotifier`. Backs
  `BlockSettingsScreen`.
- [custom_block_editor_view_model.dart](custom_block_editor_view_model.dart) —
  `CustomBlockEditorViewModel extends ChangeNotifier`. Backs
  `CustomBlockEditorScreen`. Mirrors the same draft / `isDirty` /
  save-on-leave shape:
  - `titleController` (`TextEditingController`) + `_items`
    (`List<CarouselItem>`) drafts; snapshot on construct, re-snapshot
    after `save()`.
  - `addItem`, `removeItemAt`, `moveItem` mutate the draft list.
    `moveItem` adjusts for `ReorderableListView`'s "newIndex one past
    source when moving forward" semantics so callers can pass the
    raw indices.
  - `titleError` — empty title OR case-insensitive title conflict
    with another definition in the registry. Always blocks save when
    empty; the error shows inline from first open so the requirement
    is obvious. `itemsError` — fewer than 2 items. `canSave` is
    `titleError == null && itemsError == null`.
  - `save()` writes via `addCustomCarousel` or `updateCustomCarousel`
    based on `_isNew`.

## BlockSettingsViewModel

Mirrors `LayoutEditorViewModel`'s draft / `isDirty` / save-on-leave
shape so the screen can reuse the same Cancel / Discard / Save dialog
UX. Snapshots the current `BlockSettings` on construction and only
writes back when `save()` runs — leaving with Discard reverts nothing
because nothing was written.

### State

- `_initialPrompts`, `_initialPromptStrategy`,
  `_initialCarouselTitlesEnabled` — snapshot fields used by `isDirty`
  to compare against current drafts. Re-set inside `save()` so
  post-save `isDirty` reads false.
- `promptsController` — `TextEditingController` owned by the VM
  (disposed in `dispose`). Bound by `PromptBlockSettings`.
- `_promptStrategy` — non-controller draft (Random Prompts switch).
- `_carouselTitlesEnabled` — non-controller draft (carousel-title
  switch).

### Computed

- `isDirty` — true if any parsed draft differs from its snapshot.
  Prompts compare via `listEquals` on the parsed list; strategy
  compares enum; carousel-titles-enabled compares bool.
- `canSave` — currently always `true`. Kept as a getter so the screen's
  save-on-leave dialog keeps the same code path if validation comes
  back later.

### `save()`

Writes the three BlockSettings setters in order (`setPrompts`,
`setPromptStrategy`, `setCarouselTitlesEnabled`) and re-snapshots.

## Gotchas

- **Controllers are owned by the VM, not the widget.** The screen's
  `dispose` calls `vm.dispose()`, which disposes every controller.
  Don't construct duplicates in the controlled section widgets —
  they should bind to `vm.xxxController`.
- **`isDirty` re-parses on every read.** Cheap because the text
  fields are small, but if Block Settings grows large lists, cache
  the parsed views.
- **No `nameConflict`-style remote validation** here. Title
  uniqueness lives on the `CustomBlockEditorViewModel`, not on this
  VM — there are no free-form title fields on `BlockSettingsScreen`
  anymore.

## When to update this file

- A new block-type-global setting is added (and the VM grows a
  matching draft field + controller + snapshot).
- The save-on-leave semantics change (e.g. auto-save on each field
  change instead of explicit save).
