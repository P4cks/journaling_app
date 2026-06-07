# lib/data/model/block_content — Typed wrappers over block JSON

Each `BlockType` stores its data as a `Map<String, dynamic>` inside
`JournalBlockData.contentJson` (a JSON string). The classes here are
**typed front-ends** over those maps: `fromMap` parses, `toMap` serialises.
This is the only place in the codebase that knows the wire shape of
block content.

## Files

- [text_block_content.dart](text_block_content.dart) — `TextBlockContent { String text }`. Map shape: `{"text": "..."}`.
  Missing key → empty string. The character limit (when configured)
  lives in [BlockSettings](../../services/block_settings.dart) and is
  read at render time, *not* persisted per entry. Used by
  `TextBlockWidget` and `entry_list_tile.dart`'s preview snippet.
- [photo_block_content.dart](photo_block_content.dart) — `PhotoBlockContent { String? photoPath }`.
  Map shape: `{"photoPath": "/.../photos/<uuid>.jpg"}` (key omitted when null).
  `hasPhoto` is true when `photoPath` is non-null and non-empty. The
  file itself lives under the app documents dir, written by
  [PhotoStorageService](../../services/photo_storage_service.dart);
  Hive only persists the path string. Used by `PhotoBlockWidget` and
  `JournalBlockEmptiness` (no photo → empty).
- [video_block_content.dart](video_block_content.dart) — `VideoBlockContent { String? videoPath; int? durationMs }`.
  Map shape: `{"videoPath": "/.../video/<uuid>.mp4", "durationMs": 8200}`
  (keys omitted when null). `hasVideo` is true when `videoPath` is
  non-null and non-empty. The file lives under the app documents dir,
  written by [VideoStorageService](../../services/video_storage_service.dart);
  Hive only persists the path + measured duration. `durationMs` is probed
  once at save time so the grid cell can show a badge without keeping a
  player alive. Used by `VideoBlockWidget` and `JournalBlockEmptiness`
  (no video → empty).
- [weather_api_block_content.dart](weather_api_block_content.dart) — `WeatherApiBlockContent { String? conditionId; double? temperatureC; String? cityName; String? fetchedDate; String? error }`.
  Map shape: `{"conditionId": "...", "temperatureC": 12.4, "cityName": "Berlin, Germany", "fetchedDate": "yyyy-MM-dd"}`
  (all keys omitted when null). `isFetched` is true when a condition
  is stored. Reuses the `conditionId` strings from
  [weather_block_content.dart](weather_block_content.dart) so the same
  icon mapping works for both manual and API blocks. `cityName` is the
  best-effort Nominatim reverse-geocode result; may be null if the
  reverse-geocode call failed or rate-limited. Used by `WeatherApiWidget`
  and `JournalBlockEmptiness` (unfetched → empty).
- [memory_block_content.dart](memory_block_content.dart) — `MemoryBlockContent { String? sourceEntryDate; String? sourceBlockId; BlockType? sourceType; String? snapshotJson }`.
  Map shape: `{"sourceEntryDate": "yyyy-MM-dd", "sourceBlockId": "...", "sourceType": "textBlock", "snapshotJson": "..."}`
  (all keys omitted when null). `isSeeded` getter is true when a memory
  has been picked. The `snapshotJson` field stores the source block's
  `contentJson` verbatim so future schema changes to that source type
  don't invalidate the memory. Used by `MemoryBlockWidget` and
  `JournalBlockEmptiness` (unseeded → empty).
- [quote_block_content.dart](quote_block_content.dart) — `QuoteBlockContent { String? quote; String? author; String? fetchedDate }`.
  Map shape: `{"quote": "...", "author": "...", "fetchedDate": "yyyy-MM-dd"}`
  (all keys omitted when null — absent = "not fetched yet"). Used by
  `QuoteBlockWidget` and `JournalBlockEmptiness` (no quote → empty).
  Populated by the widget on first build via [QuoteService](../../services/quote_service.dart).
- [todo_block_content.dart](todo_block_content.dart) — `TodoBlockContent { List<TodoItem> items }` + `TodoItem { String id; String text; bool done }`.
  Map shape: `{"items": [{"id": "...", "text": "...", "done": true}]}`.
  `done` is omitted when false to keep maps small; legacy entries
  without the key decode as `done: false`. Items are per-entry (no
  layout template). Used by `TodoBlockWidget` and `JournalBlockEmptiness`
  (empty list OR all-empty-text counts as empty).
- [prompt_block_content.dart](prompt_block_content.dart) — `PromptBlockContent { String prompt; String answer }`.
  Map shape: `{"prompt": "...", "answer": "..."}` (each field omitted when empty).
  `prompt` is **layout-template state** seeded from `BlockTemplate.config`
  at entry materialization. `answer` is per-entry user input. Used by
  `PromptBlockWidget` and `JournalBlockEmptiness` (only `answer.trim()`
  counts as content).
- [weather_block_content.dart](weather_block_content.dart) — `WeatherBlockContent { String? conditionId }` + a curated `weatherConditionIds` constant list (`sun`, `partly_cloudy`, `cloud`, `rain`, `thunderstorm`, `snow`, `fog`).
  Map shape: `{"conditionId": "rain"}` (or absent → `conditionId: null`).
  Newly-materialized blocks start with `conditionId: null` — the user must tap to pick. `fromMap` ignores unknown ids (returns no-selection rather than throwing). Used by `WeatherManualWidget` (manual picker) and `JournalBlockEmptiness`. The icon mapping lives in [ui/blocks/weather_manual/weather_manual_widget.dart](../../../ui/blocks/weather_manual/weather_manual_widget.dart) as a top-level `weatherIconFor` helper so the future API weather block can reuse it.
- [location_block_content.dart](location_block_content.dart) — `LocationBlockContent { double? latitude; double? longitude }`.
  Map shape: `{"latitude": 51.5, "longitude": -0.12}` (both keys omitted when no pin). `hasPin` is true when both are set. Used by `LocationBlockWidget` (long-press to drop a pin on a flutter_map view) and `JournalBlockEmptiness` (no-pin → empty).
- [mood_block_content.dart](mood_block_content.dart) — `MoodBlockContent { String? emoji }` + a curated `moodEmojis` constant list.
  Map shape: `{"emoji": "😄"}` (or absent → `emoji: null`).
  Newly-materialized blocks start with `emoji: null` — the user must tap to pick. Legacy `{"moodId": "happy"|"neutral"|"sad"}` entries are read back via
  a small migration table inside `fromMap` (happy→😄, neutral→😐, sad→😢);
  new writes only emit `emoji`. Used by `MoodTrackerWidget` and
  `JournalBlockEmptiness`.
- [custom_carousel_block_content.dart](custom_carousel_block_content.dart) — `CustomCarouselBlockContent { String? definitionId; CarouselItem? selected }`.
  Map shape: `{"definitionId": "uuid", "selected": {"kind": "emoji", "value": "⚡"}}`
  (both keys omitted when null). `definitionId` resolves to a
  [CustomCarouselDefinition](../custom_carousel_definition.dart) in
  the `BlockSettings` registry; missing/orphan → widget shows a
  deleted placeholder. `selected` is stored **verbatim** (not as an
  index) so reordering items in the definition leaves existing picks
  intact. Used by `CustomCarouselWidget` and `JournalBlockEmptiness`
  (`selected == null` → empty). The shared `CarouselItem` /
  `CarouselItemKind` types live in
  [data/model/carousel_item.dart](../carousel_item.dart).
- [habit_block_content.dart](habit_block_content.dart) — `HabitBlockContent { String? definitionId; bool completed }`.
  Map shape: `{"definitionId": "uuid", "completed": true}` (`definitionId`
  omitted when null; `completed` omitted when false — matches the
  `TodoItem` falsey-omit style). `definitionId` resolves to a
  [HabitDefinition](../habit_definition.dart) in the `BlockSettings`
  registry; missing/orphan → widget shows a deleted placeholder.
  `completed` is the per-day cross-off flag; the **streak** is derived
  by the widget from all entries, never stored. Used by
  `HabitTrackerWidget` and `JournalBlockEmptiness` (`!completed` → empty;
  habit is user-interactive so an unchecked habit gets the entry swept).

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
