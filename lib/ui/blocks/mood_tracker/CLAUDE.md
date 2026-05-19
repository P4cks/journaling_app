# lib/ui/blocks/mood_tracker — Mood tracker block widget

One `BlockType.moodTracker` block. Content shape: `{"emoji": "😄"}`
(absent → no mood selected). Typed wrapper: [MoodBlockContent](../../../data/model/block_content/mood_block_content.dart).

## Files

- [mood_tracker_widget.dart](mood_tracker_widget.dart) — `MoodTrackerWidget`.
  Stateless. Decodes `MoodBlockContent`, renders the centred emoji in
  `BlockMode.readOnly`, otherwise delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)
  which owns the PageController, expand/collapse state, and timer. The
  body is wrapped in [BlockWithTitle](../widgets/block_with_title.dart)
  with the hardcoded label `"How are you feeling?"` when
  `BlockSettings.carouselTitlesEnabled` is true (read via a
  `ListenableBuilder` on `BlockSettings`), or `null` (no title row)
  when the global toggle is off. The user does **not** edit this
  string anywhere — it is per-block-type and intentional.

## Modes

- `BlockMode.readOnly` — renders the selected emoji large and centred. When
  `emoji == null`, renders a dimmed em-dash placeholder.
- `BlockMode.editable` — delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)
  with `options: moodEmojis`. With a selection: starts collapsed
  (centred selected emoji); tapping expands a horizontal `PageView`
  of all emojis. **With no selection**: starts already-expanded so
  every emoji is visible at the dimmed/non-focused style and the
  user can swipe to commit straight away — see the carousel widget's
  CLAUDE for the always-expanded-when-empty contract. Selected page
  is full-scale + full-opacity, others scaled down + dimmed. The
  shared widget's collapse timer fires 1500 ms after **expand** (so
  tap-without-swipe still auto-collapses) and on every page change
  (each swipe restarts the 1.5 s window). `onSelected` re-encodes
  the new emoji into the block via `widget.onChanged`.

## Wire shape & migration

Persisted as `{"emoji": "<single emoji string>"}`. Legacy entries that
stored `{"moodId": "happy"|"neutral"|"sad"}` are read back via a
`_legacyMoodIdToEmoji` map in `MoodBlockContent.fromMap` (happy→😄,
neutral→😐, sad→😢). New writes only emit `emoji`. No journalEntries
box bump was needed because `JournalBlockData.contentJson` is just a
JSON string.

## Curated emoji set

`moodEmojis = ['😄','😊','😌','😐','😢','😠','😩','😍','🤔']`. Reordering
or extending the list is safe — old entries keep whatever emoji string
they persisted, regardless of position. Removing an emoji means existing
entries that stored it will still render it (string is stored, not an
index).

## Gotchas

- **Don't index `moodEmojis` to persist the selection.** Persist the
  emoji string itself; otherwise reordering the list breaks past entries.
- **The current page IS the selection.** Subtle accidental scrolling
  during list interaction could change the mood. The tap-to-expand
  guard reduces accidents from horizontal swipes meant for the outer
  date pager.
- **Persisted emojis are user-visible strings.** Renaming/normalising
  unicode forms could double-write the same logical mood; keep entries
  exactly as the picker emits them.
- **Expanded state fires `onInteractionLockChanged(blockId, true)`** via
  `CollapsibleCarouselBlock` so `JournalPager` swaps to
  `NeverScrollableScrollPhysics` and the outer swipe doesn't fight
  the carousel. The release lives inside the shared widget; this
  block doesn't have its own dispose path. See
  [widgets/CLAUDE.md](../widgets/CLAUDE.md) for the full lifecycle.

## When to update this file

- The emoji set changes (add/remove).
- The carousel mechanic changes (e.g. tap-to-select rather than
  swipe-as-selection).
- The legacy `moodId` migration is removed (would require a journalEntries
  box bump to drop old entries cleanly).
