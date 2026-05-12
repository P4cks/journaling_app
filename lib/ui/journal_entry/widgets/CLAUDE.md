# lib/ui/journal_entry/widgets — Editor-screen widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [editor_title.dart](editor_title.dart) — `EditorTitle` (StatefulWidget)
  + internal `_InlineTitleField`. The AppBar title for the editor.
  - **Default render**: title text (falls back to `formatEntryDate(date)`
    when null). Tappable when `editable`, swaps in a `TextField`.
  - **Editing render**: inline `TextField` + a date-line subtitle.
  - **Subtitle visibility**: shown when a custom title exists, or
    while editing. Hidden when there's no custom title and not editing,
    so the date isn't duplicated.

## Editing flow

- `_startEditing` — fills the controller with current title, requests
  focus in a post-frame callback, selects-all so a user can type-over.
- `_commit` — calls `onChanged(controller.text)`. The VM normalizes
  empty/whitespace → `null` (date fallback), so the widget doesn't have
  to.
- `_cancel` — reverts the controller, dropping the in-progress edit.
- Focus-loss commits implicitly (`_onFocusChange` calls `_commit`).
  There's no explicit cancel affordance in the AppBar; tapping away
  acts as commit-as-typed.

## Gotchas

- **`didUpdateWidget` syncs the controller from `widget.title`** but
  only when `!_isEditing`. If you don't guard this, an in-flight save
  notification can stomp the user's caret while they type.
- **Don't try to commit on Enter and ignore focus-loss.** Tapping
  outside the field happens often (the body has an unfocus
  GestureDetector). Both pathways must commit, or users will think
  their edit was lost.

## When to update this file

- The title-editing UX changes (e.g. a separate detail screen).
- New AppBar widgets are added that need to coordinate with title
  focus state.
