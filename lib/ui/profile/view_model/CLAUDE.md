# lib/ui/profile/view_model — Profile-area view models

See [../CLAUDE.md](../CLAUDE.md) for the area overview.

## Files

- [block_settings_view_model.dart](block_settings_view_model.dart) —
  `BlockSettingsViewModel extends ChangeNotifier`. Backs
  `BlockSettingsScreen`.

## BlockSettingsViewModel

Mirrors `LayoutEditorViewModel`'s draft / `isDirty` / save-on-leave
shape so the screen can reuse the same Cancel / Discard / Save dialog
UX. Snapshots the current `BlockSettings` on construction and only
writes back when `save()` runs — leaving with Discard reverts nothing
because nothing was written.

### State

- `_initialPrompts`, `_initialPromptStrategy`, `_initialTextCharLimit`,
  `_initialMoodTitle`, `_initialWeatherTitle` — snapshot fields used
  by `isDirty` to compare against current drafts. Re-set inside
  `save()` so post-save `isDirty` reads false.
- `promptsController`, `textCharLimitController`, `moodTitleController`,
  `weatherTitleController` — `TextEditingController`s owned by the VM
  (disposed in `dispose`). Bound by the section widgets.
- `_promptStrategy` — non-controller draft (segmented button).

### Computed

- `isDirty` — true if any parsed/normalised draft differs from its
  snapshot. Prompts compare via `listEquals` on the parsed list;
  titles compare after trim + null-empty normalisation; char limit
  compares parsed int.
- `textCharLimitError` — non-null when the field has content but
  isn't a positive whole number. Surfaced on the TextField and gates
  `canSave`.
- `canSave` — `textCharLimitError == null`. The save-on-leave dialog
  surfaces a SnackBar and stays on the screen when this is false.

### `save()`

Writes the four BlockSettings setters in order (`setPrompts`,
`setPromptStrategy`, `setTextCharLimit`, `setMoodTitle`,
`setWeatherTitle`) and re-snapshots. Returns false (without writing)
when validation fails.

## Gotchas

- **Controllers are owned by the VM, not the widget.** The screen's
  `dispose` calls `vm.dispose()`, which disposes every controller.
  Don't construct duplicates in the controlled section widgets —
  they should bind to `vm.xxxController`.
- **`isDirty` re-parses on every read.** Cheap because the text
  fields are small, but if Block Settings grows large lists, cache
  the parsed views.
- **No `nameConflict`-style remote validation** here — the title
  fields are free-form. The next-phase custom-block sections will
  add unique-title validation.

## When to update this file

- A new block-type-global setting is added (and the VM grows a
  matching draft field + controller + snapshot).
- The save-on-leave semantics change (e.g. auto-save on each field
  change instead of explicit save).
