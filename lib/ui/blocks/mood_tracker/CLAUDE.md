# lib/ui/blocks/mood_tracker — Mood tracker block widget

One `BlockType.moodTracker` block. Content shape: `{"emoji": "😄"}`
(absent → no mood selected). Typed wrapper: [MoodBlockContent](../../../data/model/block_content/mood_block_content.dart).

## Files

- [mood_tracker_widget.dart](mood_tracker_widget.dart) — `MoodTrackerWidget`.
  Stateful — owns the `PageController` so swipe position survives rebuilds.

## Modes

- `BlockMode.readOnly` — renders the selected emoji large and centred. When
  `emoji == null`, renders a dimmed em-dash placeholder.
- `BlockMode.editable` — horizontal `PageView` (carousel) of the curated
  emoji set (`moodEmojis` constant in [mood_block_content.dart](../../../data/model/block_content/mood_block_content.dart)). Each page shows one emoji; selected page is full-scale + full-opacity, others scaled down + dimmed. `onPageChanged` writes the centred emoji as the selection (swiping to a page selects it). `FocusScope.of(context).unfocus()` runs on every page change to dismiss any text-field keyboard from a neighbouring block.

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
  during list interaction could change the mood. This is acceptable
  per the chosen UX; if it becomes a problem, switch to "tap to select"
  with separate browsing.
- **Persisted emojis are user-visible strings.** Renaming/normalising
  unicode forms could double-write the same logical mood; keep entries
  exactly as the picker emits them.

## When to update this file

- The emoji set changes (add/remove).
- The carousel mechanic changes (e.g. tap-to-select rather than
  swipe-as-selection).
- The legacy `moodId` migration is removed (would require a journalEntries
  box bump to drop old entries cleanly).
