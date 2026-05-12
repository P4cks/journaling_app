# lib/data/model/block_content — Typed wrappers over block JSON

Each `BlockType` stores its data as a `Map<String, dynamic>` inside
`JournalBlockData.contentJson` (a JSON string). The classes here are
**typed front-ends** over those maps: `fromMap` parses, `toMap` serialises.
This is the only place in the codebase that knows the wire shape of
block content.

## Files

- [text_block_content.dart](text_block_content.dart) — `TextBlockContent { String text }`. Map shape: `{"text": "..."}`.
  Missing key → empty string. Used by `TextBlockWidget` and
  `entry_list_tile.dart`'s preview snippet.
- [weather_block_content.dart](weather_block_content.dart) — `WeatherBlockContent { String? conditionId }` + a curated `weatherConditionIds` constant list (`sun`, `partly_cloudy`, `cloud`, `rain`, `thunderstorm`, `snow`, `fog`).
  Map shape: `{"conditionId": "rain"}` (or absent → `conditionId: null`).
  `fromMap` ignores unknown ids (returns no-selection rather than throwing). Used by `WeatherManualWidget` (manual picker) and `JournalBlockEmptiness`. The icon mapping lives in [ui/blocks/weather_manual/weather_manual_widget.dart](../../../ui/blocks/weather_manual/weather_manual_widget.dart) as a top-level `weatherIconFor` helper so the future API weather block can reuse it.
- [mood_block_content.dart](mood_block_content.dart) — `MoodBlockContent { String? emoji }` + a curated `moodEmojis` constant list.
  Map shape: `{"emoji": "😄"}` (or absent → `emoji: null`).
  Legacy `{"moodId": "happy"|"neutral"|"sad"}` entries are read back via
  a small migration table inside `fromMap` (happy→😄, neutral→😐, sad→😢);
  new writes only emit `emoji`. Used by `MoodTrackerWidget` and
  `JournalBlockEmptiness`.

## Implementation details

- Every wrapper exposes the same two-method shape: `factory T.fromMap(Map)`
  and `Map<String, dynamic> toMap()`. Keep that contract when adding a
  new block type — call sites (block widgets, emptiness extension) are
  already grep-able by `.fromMap(` / `.toMap()`.
- `toMap()` omits absent values (the mood wrapper uses a `if (mood != null)`
  collection-if) so we don't persist `{"moodId": null}`. This keeps
  JSON small and makes "absent" and "explicitly null" the same on
  deserialise.
- `fromMap` must be **tolerant of missing or unknown keys**: this map
  comes from a JSON blob persisted from a previous (possibly older)
  app version. Default to a sensible empty value; never throw.

## Gotchas

- **The shape of these maps is a long-lived data contract.** A
  rename like `text` → `body` would silently break existing entries
  unless you keep a read-fallback. Prefer adding new keys with
  defaults over renaming.
- **Don't put `JournalBlockData` references in here.** These wrappers
  must stay map-in / map-out so they can be unit-tested without touching
  the block-data class.

## When to update this file

- A new block type's content wrapper is added.
- The wire shape of an existing wrapper changes (and add a read-fallback
  comment so the next agent knows older entries are still legal).
