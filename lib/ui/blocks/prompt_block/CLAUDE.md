# lib/ui/blocks/prompt_block — Prompt block widget

One `BlockType.promptBlock` block. Renders a question (chosen from the
user's global prompt list) above an editable answer field. Content
shape: `{"prompt": "...", "answer": "…"}`. Typed wrapper:
[PromptBlockContent](../../../data/model/block_content/prompt_block_content.dart).

## Files

- [prompt_block_widget.dart](prompt_block_widget.dart) —
  `PromptBlockWidget`. Stateful (owns its `TextEditingController`).

## How the prompt gets there

The prompt is **baked into the entry's content at materialization time**
by [JournalRepository.materializeLayout](../../../data/repositories/journal_repository.dart),
which calls [BlockSettings.pickPromptFor](../../../data/services/block_settings.dart).
That means:

- The prompt list and strategy (`daily` / `random`) are configured
  globally in Profile → Block settings → Prompt block.
- The pick happens **once**, the day the entry is created, and lives
  in the entry's `contentJson` forever — re-opening the entry never
  re-rolls.
- Editing the prompt list afterwards only affects entries created
  *after* the edit. Historical entries are immutable in this respect.
- Empty prompt list (or none configured at materialization time) →
  the widget renders a dimmed italic "No prompt set" placeholder.

The widget therefore reads the prompt from `widget.data.content`, not
from `BlockSettings`. The settings object is only consulted by the
repository at create time.

## Modes

- `BlockMode.readOnly` — prompt label on top (primary-colored,
  semibold), then the user's answer or "Not answered yet" italic
  placeholder.
- `BlockMode.editable` — prompt label on top, then a multi-line
  `TextField` that fills the remaining vertical space (`Expanded` +
  `expands: true`). Same per-keystroke save pattern as the text block.

## Gotchas

- **The widget must round-trip `prompt` on every emit.** When the user
  types into the answer field, the widget reconstructs the content map
  with both `prompt` *and* `answer` so the prompt survives the next
  read. Don't drop the prompt argument from `_emit`.
- **Empty `answer` makes the block empty** for sweep purposes — the
  prompt text alone doesn't count.

## When to update this file

- The content shape gains a new field (e.g. `placeholder`).
- The prompt selection strategy changes (e.g. user-overridable per
  entry).
- `BlockSettings.pickPromptFor` gains new strategies — describe them
  here and in [data/services/CLAUDE.md](../../../data/services/CLAUDE.md).
