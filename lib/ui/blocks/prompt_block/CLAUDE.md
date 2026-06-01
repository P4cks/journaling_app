# lib/ui/blocks/prompt_block — Prompt block widget

One `BlockType.promptBlock` block. Renders a question (chosen from the
user's global prompt list, or picked manually by the user) above an
editable answer field. Content shape: `{"prompt": "...", "answer": "…"}`.
Typed wrapper:
[PromptBlockContent](../../../data/model/block_content/prompt_block_content.dart).

## Files

- [prompt_block_widget.dart](prompt_block_widget.dart) —
  `PromptBlockWidget`. Stateful (owns its `TextEditingController` and
  a one-shot auto-picker flag).
- [prompt_picker_sheet.dart](prompt_picker_sheet.dart) —
  `Future<String?> showPromptPickerSheet(context, {prompts, selected})`.
  Modal bottom sheet listing the configured prompts plus a "Type
  custom prompt…" tile that swaps into a `TextField`. Returns the
  picked prompt string, or `null` on dismiss. Custom-typed prompts are
  one-off — they are **not** appended to `BlockSettings.prompts`.

## How the prompt gets there

The prompt is **baked into the entry's content at materialization time**
by [JournalRepository.materializeLayout](../../../data/repositories/journal_repository.dart),
which calls [BlockSettings.pickPromptFor](../../../data/services/block_settings.dart).
That means:

- The prompt list and strategy (`random` or `manual`) are configured
  globally in Profile → Block settings → Prompt block. The strategy is
  surfaced as a "Random Prompts" `SwitchListTile`: ON (default) =
  `random`, OFF = `manual`. (Legacy `daily` values on existing devices
  read back as `random`.)
- For `random`: the pick happens **once**, the day the entry is created,
  and lives in the entry's `contentJson` forever — re-opening the entry
  never re-rolls. "Random" here describes the user-perceived behavior
  (a different prompt each day), not non-determinism — the pick is
  deterministic from `(daysSinceEpoch + slotIndex) mod N`.
- For `manual`: `pickPromptFor` returns `null`, the materialized
  prompt is empty, and the widget opens the picker sheet automatically
  on first build of the editable view.
- Editing the prompt list afterwards only affects entries created
  *after* the edit (for `random`); for `manual`, the next picker open
  reflects the updated list immediately.
- Empty prompt list AND `random` strategy → the widget renders a dimmed
  italic "No prompt set" placeholder. In editable mode the placeholder
  becomes "Tap to pick a prompt".

The widget reads the prompt from `widget.data.content`. It only reads
`BlockSettings` to source the picker's list — never to pick on its own.

## Picker UX

- **Auto-open on first build** — `didChangeDependencies` checks
  `widget.mode == editable && content.prompt.isEmpty` and, if so,
  schedules `showPromptPickerSheet` via
  `WidgetsBinding.instance.addPostFrameCallback`. A `_autoPromptShown`
  flag prevents re-firing on theme changes or other dependency churn.
- **Pencil button to re-pick** — when the prompt is set and the
  block is editable, a small 22×22 `IconButton(HugeIcons.strokeRoundedPencil)`
  sits next to the prompt label and opens the picker on tap.
  Replaces the prior outer `GestureDetector(onLongPress: …)` — that
  long-press raced `BlockGrid`'s `LongPressDraggable` and silently
  opened the picker mid-drag. The icon owns its own tap target; the
  rest of the tile (including the answer field) is free for drag-
  to-reorder and the standard double-tap-to-engage flow.
- **Tap to recover** — if the user dismisses the auto-picker, the
  editable view shows a "Tap to choose" body that re-opens the picker.
  The pencil button is suppressed in this state to avoid two
  affordances for the same action.
- **Re-pick with existing answer** — if the user re-picks a different
  prompt and the answer is non-empty, a confirm dialog offers
  `Cancel` / `Clear it` / `Keep my answer`. `Cancel` aborts; `Clear`
  resets the answer; `Keep` preserves it under the new prompt.

## Modes

- `BlockMode.readOnly` — prompt label on top (primary-colored,
  semibold), then the user's answer or "Not answered yet" italic
  placeholder. No picker, no long-press.
- `BlockMode.editable` — prompt label + pencil button on top, then a
  multi-line `TextField` that fills the remaining vertical space
  (`Expanded` + `expands: true`). Picker auto-opens on empty-prompt
  first build; tapping the pencil re-opens it. Same per-keystroke
  save pattern as the text block.

## Gotchas

- **Never show a modal directly from `didChangeDependencies`** —
  always defer via `addPostFrameCallback`. `didChangeDependencies` can
  fire multiple times (theme changes, etc.), and a directly-pushed
  route is racy.
- **The widget must round-trip `prompt` on every emit.** When the user
  types into the answer field, the widget reconstructs the content map
  with both `prompt` *and* `answer` so the prompt survives the next
  read. Don't drop the prompt argument from `_emit`.
- **Empty `answer` makes the block empty** for sweep purposes — the
  prompt text alone doesn't count.
- **Custom-typed prompts are entry-local**, not added to the global
  list. If users start asking for "save this prompt", revisit by
  promoting the typed value into `BlockSettings.setPrompts` before
  emitting.

## When to update this file

- The content shape gains a new field (e.g. `placeholder`).
- The prompt selection strategy changes — `BlockSettings.pickPromptFor`
  gains new variants, or the auto-open / long-press semantics shift.
- The picker sheet UX changes (e.g. search, multi-pick, save-to-list).
