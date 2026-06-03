# lib/ui/blocks/header_section — Single-line heading section

The widget used for `SectionKind.header` sections in the journal pager
(GUS-6, FREE). Renders a large bold one-liner used to break up an entry
into visual chunks.

## Files

- [header_section_widget.dart](header_section_widget.dart) —
  `HeaderSectionWidget`. Stateful (uses
  [TextContentControllerMixin](../widgets/text_content_controller_mixin.dart)
  for the controller/focus lifecycle + per-keystroke `emitText`).

## Content shape

Backed by a `JournalBlockData(type: BlockType.textBlock)` — the same
`TextBlockContent` (`{"text": "..."}`) used by the 1×1 text block and
the full-width text section. Reuses the existing JSON path + emptiness
classification, so no new content type / Hive change. `materializeLayout`
seeds a `header` section with exactly one fresh empty `textBlock`
(copying the `text` case).

## Modes

- `BlockMode.readOnly` — a bold `titleLarge` `Text`. Empty heading shows
  "Heading" in italic + `disabledColor`.
- `BlockMode.editable` — a capped single-line `TextField(maxLines: 1)`
  styled `titleLarge` bold, hint "Heading", `maxLength:
  kHeaderSectionMaxChars` (60), counter via
  `buildCharCounter(onlyWhenFocused: true)`.

## Differences from `TextSectionWidget`

- **No expanded route, no Hero.** A heading is one short line — it edits
  in place. The journal pager renders it directly (not Hero-wrapped).
- **No `AbsorbPointer` / `DelayedTapFocus`.** The field is directly
  single-tap focusable; there's no double-tap-to-expand affordance to
  protect against, so the two-tap dance is unnecessary. The `editing`
  prop is still forwarded to the mixin (so a future in-place edit-mode
  detector could drive programmatic focus), but in practice focus comes
  from the user's direct tap.

## When to update this file

- The header gains structure (alignment options, size variants).
- The char cap or the placeholder text changes.
