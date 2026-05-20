# lib/data/model — Plain data classes

Pure Dart value-ish classes. **No Hive annotations** — adapters are
generated from the `@GenerateAdapters` list in [hive/hive_adapters.dart](../../hive/hive_adapters.dart).
That means: the fields declared in these classes are the contract the
generated `hive_adapters.g.dart` and `hive_registrar.g.dart` lock onto.

## Files

- [journal_entry.dart](journal_entry.dart) — `JournalEntry`. Fields:
  `id` (uuid), `date` (DateTime — repository normalizes to local-midnight
  before keying), `lastModified`, `sections` (`List<EntrySection>`),
  `title` (`String?` — when null, the editor / list fall back to the
  formatted date).
  - `copyWith` supports explicit-null on `title` via `clearTitle: true`.
    Don't try to round-trip `null` through the `title` named param —
    `null` means "keep existing".
- [entry_section.dart](entry_section.dart) — `EntrySection`. One
  ordered section of a `JournalEntry`. Fields: `id`, `kind`
  (`SectionKind`), `rows` (nullable; `blockGrid` only), `blocks`
  (`List<JournalBlockData>`). For `SectionKind.text` the blocks list
  is exactly `[JournalBlockData(type: textBlock)]` — the text content
  lives in that single block's `TextBlockContent`, reusing the
  existing text JSON path and char-limit enforcement. For
  `SectionKind.featureBlock` the blocks list contains exactly one
  materialized block (a `photoBlock` or `memoryBlock`) rendered at
  2×2 (full body width, square).
- [section_kind.dart](section_kind.dart) — `enum SectionKind { text, blockGrid, featureBlock }`.
  Discriminator for both `LayoutSection` and `EntrySection`. **Append-only.**
  `featureBlock` is a single-tile 2×2 section; the layout editor
  restricts the block type to `photoBlock` or `memoryBlock` (defended
  by `LayoutEditorViewModel.featureBlockAllowedTypes`).
- [layout_kind.dart](layout_kind.dart) — `enum LayoutKind { blockOnly, fixedFourPlusText, custom }`.
  Picked by the user at layout-creation time; drives the layout editor's
  UX. **Append-only.**
- [journal_block_data.dart](journal_block_data.dart) — `JournalBlockData`.
  Fields: `id`, `type` (`BlockType`), `contentJson` (string),
  `visualsJson` (string, defaults to `'{}'`). The `contentJson` field
  is the schema-free escape hatch: each block type encodes its data
  as JSON inside it. Typed accessors live in
  [block_content/](block_content/). Use the `JournalBlockData.create`
  factory (takes a `Map` for content + an optional `BlockVisuals`)
  rather than passing raw JSON strings.
  - **`visualsJson`** carries the post-it look (per-entry rotation,
    offset, color hex) as a separate envelope so block-content
    wrappers can stay focused on their own shape. Parsed lazily via
    the `visuals` getter (`BlockVisuals.fromJson`).
  - **`copyWith({contentJson, content, visuals})`** is the safe way
    to update a block — it preserves `visualsJson` when only
    `content` changes (use this in widget edit paths). Calling
    `JournalBlockData.create(...)` without a `visuals` arg would
    reset the visuals to zero, which wipes the random seed; the
    `_materializeOne` path is the only place that legitimately
    constructs fresh visuals via `BlockVisuals.random`.
- [block_visuals.dart](block_visuals.dart) — `BlockVisuals`. Plain
  value class wrapping the post-it look:
  `{ rotationDeg (-2..+2), offsetX (-4..+4), offsetY (-4..+4), colorHex }`.
  `fromMap` / `fromJson` are tolerant of missing keys (return
  `BlockVisuals.zero`); `toMap` omits zero values to keep persisted
  JSON small. `BlockVisuals.random(rng, paletteHex)` is the seed
  used at entry materialization.
- [block_type.dart](block_type.dart) — `enum BlockType { textBlock, moodTracker, weatherManual, promptBlock, todoBlock, quoteBlock, memoryBlock, weatherApi, photoBlock, locationBlock, customCarousel }`.
  **New values MUST be appended at the end** — Hive serializes enum
  values by index, so inserting or reordering would corrupt existing
  entries on disk. Adding a new variant requires (a) a wrapper in
  `block_content/`, (b) a widget under `lib/ui/blocks/<type>/`,
  (c) cases in [block_widget.dart](../../ui/blocks/block_widget.dart),
  [block_type_display.dart](../../ui/blocks/block_type_display.dart),
  [journal_entry_emptiness.dart](journal_entry_emptiness.dart) — both
  `JournalBlockEmptiness.isEmpty` (per-type emptiness) **and**
  `BlockTypeInteraction.isUserInteractive` (user-driven vs. auto-seeded
  — decides whether content keeps the entry alive past the midnight
  sweep), and
  [JournalRepository._materializeOne](../repositories/journal_repository.dart),
  and (d) `flutter pub run build_runner build`.
- [journal_layout.dart](journal_layout.dart) — `JournalLayout`. Fields:
  `id`, `name`, `kind` (`LayoutKind`), `sections`
  (`List<LayoutSection>` — the structural template; see
  `LayoutSection` below), `iconName` (`String?` — stable identifier
  like `"squaresFour"` carried over from the pre-HugeIcons Phosphor
  era, resolved to a HugeIcons glyph via
  [ui/layouts/layout_icons.dart](../../ui/layouts/layout_icons.dart)).
  `copyWith` has `clearIcon: true` for explicit-null on `iconName`.
- [layout_section.dart](layout_section.dart) — `LayoutSection`. One
  ordered section of a `JournalLayout`. Fields: `id`, `kind`
  (`SectionKind`), `rows` (nullable; `blockGrid` only — 1..4 in the
  editor), `blocks` (`List<BlockTemplate>` — empty for text sections,
  exactly `2 * rows` templates for block-grid sections, exactly one
  template for `featureBlock` sections). Each template is materialized
  one-for-one into a `JournalBlockData` when the entry is created.
- [block_template.dart](block_template.dart) — `BlockTemplate { String id; BlockType type; String configJson }`.
  The per-slot envelope inside `LayoutSection.blocks`. Mirrors
  `JournalBlockData`'s `contentJson` shape. The current model only
  uses `type`; `configJson` defaults to `'{}'` and is kept around so
  per-template overrides can be added later without another Hive
  schema bump. Block-type-global configuration lives in
  [BlockSettings](../services/block_settings.dart) instead — read at
  materialization (`JournalRepository.materializeLayout`) or at render
  time (`TextBlockWidget`).
- [journal_entry_emptiness.dart](journal_entry_emptiness.dart) — three
  extension methods:
  - `BlockType.isUserInteractive` — whether the block's content comes
    from explicit user action. User-interactive blocks (text, mood,
    weatherManual, prompt, todo, photo, location) keep an entry alive;
    auto-seeded blocks (quote, memory, weatherApi) populate themselves
    from APIs / repo state and must NOT keep an otherwise-untouched
    entry alive. **Every new `BlockType` MUST be classified here** —
    see the doc comment for the rule of thumb.
  - `JournalBlockData.isEmpty` — per-type emptiness; unknown types are
    conservatively treated as **non-empty** so we never sweep something
    we don't yet understand.
  - `JournalEntry.hasNoContent` — true when `sections.isEmpty` or
    every **user-interactive** block is empty. Auto-seeded blocks are
    skipped (so a successful quote/weather-API fetch doesn't keep an
    untouched entry from being swept). Title is intentionally ignored
    — a title alone doesn't count as content. Used by both
    `JournalRepository.sweepEmptyPastEntries` and `computeStreak` to
    decide what counts.
- [app_user.dart](app_user.dart) — `AppUser`. Auth-facing value object
  with `uid`, optional email/display name/photo URL, provider IDs, and
  email verification state. This is the UI/cloud boundary for future
  Firestore/Storage work; do not expose Firebase `User` objects above
  the service layer.
- [carousel_item.dart](carousel_item.dart) — `CarouselItem` + `enum
  CarouselItemKind { emoji, icon }`. Discriminated union of "this is an
  emoji string" vs "this is a curated icon name" (resolves to a
  HugeIcons glyph via the carousel icon catalogue; the stable string
  ids originated as Phosphor identifiers and are preserved as-is).
  Used by custom-carousel definitions AND by the per-block selection
  content. `fromMap` defaults unknown `kind` to `emoji` for forward
  compat.
- [custom_carousel_definition.dart](custom_carousel_definition.dart) —
  `CustomCarouselDefinition` (`id`, `title`, `items`). Lives in the
  `BlockSettings` registry; referenced by id from `BlockTemplate.configJson`
  (layout slots) and from `CustomCarouselBlockContent`. Pure JSON
  serialization; nothing Hive-adapter-y because the values live in the
  schema-free `settings` box, not in the layouts / entries box.

## Implementation details

- **`==` and `hashCode` are not overridden.** Don't rely on value
  equality for these classes — use field-by-field comparison or `id`
  comparison. The `Set<DateTime>` in `HomeViewModel.entriesByDay` is
  why date normalization is mandatory: two `DateTime` instances with
  different times-of-day are unequal even on the same calendar day.
- **`toString` is defined for debug-friendly logs** — repositories and
  view models log via `debugPrint('[Name] ... $entry')`. Keep `toString`
  short and never `jsonEncode` `contentJson` inside it (could be large).
- **All fields are `final`.** Mutation happens via `copyWith`.

## Gotchas

- **Hive adapter regeneration is required** when you add / remove /
  reorder fields on any of these classes (because they appear in
  `hive_adapters.dart`'s `@GenerateAdapters` list). If you forget,
  compile fails because `hive_adapters.g.dart` is stale. The fix is
  always `$FLUTTER pub run build_runner build --delete-conflicting-outputs`.
- **Renaming or retyping a field breaks deserialization of existing
  Hive data.** Bump the box name in `main.dart` (see root CLAUDE.md).
  The old box stays on disk and is harmless — but it's wasted bytes,
  so eventually clean up.
- **`contentJson` is the long-lived persistence contract for block
  data.** Treat changes to a block's content map the same as a schema
  change: the `fromMap` factories in `block_content/` must stay
  tolerant of older shapes (return defaults for missing keys).

## When to update this file

- A new model class is added or one is deleted.
- A field is added, removed, or retyped on any of these classes (and
  remember to bump the box name).
- The "what counts as empty" rules change in `journal_entry_emptiness.dart`.
