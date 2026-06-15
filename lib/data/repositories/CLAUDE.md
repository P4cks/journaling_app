# lib/data/repositories — Domain operations

Repositories compose storage services to provide domain-level operations.
This is where keying conventions, default-resolution, and cross-box
coordination live.

## Files

- [auth_repository.dart](auth_repository.dart) — `AuthRepository extends ChangeNotifier`.
  Listens to `AuthService.authStateChanges` and exposes `currentUser`,
  `isConfigured`, loading state, active `AuthOperation`, and readable
  error/success messages. Public methods wrap email sign-in/register,
  password reset, Google, Apple, and sign-out. UI should use this
  repository instead of importing Firebase SDK classes.
- [subscription_repository.dart](subscription_repository.dart) —
  `SubscriptionRepository extends ChangeNotifier`. Wraps
  [SubscriptionService](../services/subscription_service.dart) **and**
  [SettingsStorageService](../services/settings_storage_service.dart)
  (constructor: `SubscriptionRepository(service, settings)`). Exposes a
  single `isPro` getter resolved in three tiers:
  1. **Debug override** — when `debugForceFree` is on, `isPro` is always
     `false` (lets developers test the free experience; toggled from
     Settings → Debug "Simulate free account" via `setDebugForceFree`).
     This does **not** touch the real RevenueCat subscription — the
     client SDK has no cancel API, so this is a local mask only.
  2. **Live entitlement** — `CustomerInfo.entitlements.active` contains
     `kProEntitlementId` (SDK-cached, so it works offline once the SDK
     has cached at least once).
  3. **Offline failsafe** — when we have *no* `CustomerInfo` at all
     (e.g. a cold start that threw offline), falls back to the persisted
     `subscription.lastKnownPro` flag. That flag snapshots the **real**
     entitlement on every customer-info update (`_applyCustomerInfo`),
     never the debug override, so toggling the override can't corrupt
     the failsafe.
  Subscribes to the RevenueCat customer-info update listener in its
  constructor (mirrors `AuthRepository`'s stream subscription) and
  removes it in `dispose`. `init()` (called once from `main.dart` after
  `SubscriptionService.configure`) fetches initial `CustomerInfo` +
  `Offerings`, **swallowing failures** so an offline launch falls
  through to the persisted flag; `restore()` re-applies prior purchases.
  `ensureOfferings()` (re)loads the current offering and returns whether
  a paywall can be presented — the Pro gate
  ([pro_gate.dart](../../ui/core/widgets/pro_gate.dart)) calls it to
  detect "offline / can't buy" before presenting RevenueCat's paywall.
  `hasOfferings` exposes the same state synchronously. The live
  entitlement is SDK-cached (not in Hive); only the `lastKnownPro` /
  `debugForceFree` booleans are persisted (settings box). A purchase
  made on the `RevenueCatUI` paywall flips `isPro` automatically (no
  manual `purchasePackage`). UI reads `isPro` for gates (e.g.
  [LayoutsScreen](../../ui/layouts/view/layouts_screen.dart),
  [StatRangeSelector](../../ui/statistics/widgets/stat_range_selector.dart))
  and the
  [SubscriptionScreen](../../ui/subscription/view/subscription_screen.dart).
- [journal_repository.dart](journal_repository.dart) — `JournalRepository extends ChangeNotifier`.
  - **Date keying**: `_normalize(d)` strips time-of-day → `DateTime(y, m, d)`;
    `_dateKey(d)` is `_normalize(d).toIso8601String()`. **All public
    methods normalize their inputs**, so callers may pass any `DateTime`.
  - `getEntryForDate(date)` — synchronous read.
  - `createEntryForDate(date, {layout})` — synchronous create + async
    save. Uses the user's default layout when `layout == null`. **Does
    not check for an existing entry** — that's the caller's job.
    Calls `materializeLayout` to produce the entry's blocks.
  - `materializeLayout(layout, date)` — turns a layout's
    `List<LayoutSection>` into a fresh `List<EntrySection>`. Per
    section:
    - `SectionKind.text` — yields an `EntrySection` whose `blocks`
      list is exactly one fresh `JournalBlockData(type: textBlock)`
      with empty `TextBlockContent`. This reuses the text-block JSON
      path so the existing emptiness check carries over unchanged.
    - `SectionKind.blockGrid` — materializes one `JournalBlockData`
      per `BlockTemplate` in the section's `blocks` list. Per-type
      seeding (same as before):
      - `promptBlock` — calls `BlockSettings.pickPromptFor(date,
        slotIndex)`. `slotIndex` is **layout-wide** (a single
        counter across every block-grid section), so two prompt
        blocks in different sections on the same day still get
        different prompts under `random` strategy.
      - All other types — empty content map. Mood and weather start
        with no selection (`emoji: null` / `conditionId: null`), so an
        untouched entry remains empty per `JournalBlockEmptiness` and
        gets swept at end of day if the user never interacts.
    - `SectionKind.header` — yields an `EntrySection` whose `blocks`
      list is exactly one fresh empty `textBlock` (copy of the `text`
      case — reuses the text JSON path + emptiness classification).
    - `SectionKind.divider` — yields an `EntrySection` with `blocks:
      const []` (purely visual; contributes nothing to emptiness).
    - `SectionKind.blockTextBody` — yields an `EntrySection` whose
      `blocks` list is `[if (template present) materialized float
      block, fresh empty textBlock]`. The float block (0 or 1
      template) can be **any** `BlockType` (GUS-46) and materializes
      like `featureBlock` (custom/habit floats carry their
      `definitionId` through `_materializeOne`); the `textBlock` is
      fresh + empty like `text` and **always appended last**. The pager
      keys off this order (body = `blocks.last`), not block type, so a
      float that is itself a `textBlock` stays unambiguous.
    - `SectionKind.wannado` — yields an `EntrySection` with `blocks:
      const []` (content-free) but **carries `section.definitionId`
      across** from the layout section. The section renders the matching
      `WannadoDefinition` off `BlockSettings` at render time; nothing
      else is materialized into the entry. Like `divider`, contributes
      nothing to emptiness — so an entry whose only section is wannado is
      swept at midnight if otherwise untouched (a wanna-do is not
      per-entry content).
    Public so the editor's `applyLayout` path uses the same code.
  - `saveJournalEntry(entry)` — async write, notifies on completion.
  - `deleteEntry(entry)` — async delete, notifies.
  - `deleteAllEntries()` — destructive bulk delete used by the
    debug menu. Iterates every entry and removes it; notifies once
    if any were deleted. Returns the count. Layouts and settings
    are untouched.
  - `debugGenerateSampleEntries({days = 400, density = 0.7})` —
    **debug-only** (GUS-35); backs the Settings → Debug "Generate
    sample entries" action. Walks the past `days` days, and for ~`density`
    of them (and only when no entry already exists for that date)
    writes a self-contained entry: one `blockGrid` section holding a
    `textBlock` (random word count via `_sampleText`) + a `moodTracker`
    (random `moodEmojis` pick via `_sampleMood`, ~15% left null so the
    mood-over-time line shows gaps). Today is skipped (loop starts at
    `back = 1`). Notifies once if any were created; returns the count.
    Non-destructive — never overwrites existing entries.
  - `getAllEntries()` — unsorted; sorting is caller's job
    (`JournalEntriesViewModel` and `HomeViewModel.entriesByDay`
    each do their own).
  - `pickRandomEligibleBlock({beforeDate, eligibleTypes})` — used by
    [MemoryBlockWidget](../../ui/blocks/memory_block/memory_block_widget.dart)
    to seed itself. Walks every section of every entry strictly
    before `beforeDate`, filters to blocks whose `type` is in
    `eligibleTypes` AND whose `isEmpty` is false (per
    `JournalBlockEmptiness`), and uniformly samples. Returns
    `(date, block)` or `null` when the pool is empty. The caller
    persists the snapshot into the entry's content so the pick is
    locked.
  - `sweepEmptyPastEntries({now})` — deletes past-day entries whose
    every **user-interactive** block is empty (per
    `JournalEntry.hasNoContent`). Auto-seeded blocks (quote, memory,
    weather API) are intentionally ignored — a successful API fetch on
    an otherwise-untouched entry should NOT keep it alive past
    midnight. Today's entries are never deleted (user may still be
    drafting). Returns the count; notifies once if anything was
    deleted. **Called from three places**: `main.dart` cold-start,
    `MyApp`'s `didChangeAppLifecycleState` resume, and
    `HomeScreen._openEditor` on editor-pop.
- [layout_repository.dart](layout_repository.dart) — `LayoutRepository`.
  **Not a `ChangeNotifier`** (layout edits are infrequent and the
  Layouts screen refreshes manually on push-pop). Methods:
  - `getAll`, `getById`, `save`, `delete` — straightforward.
  - `getDefault` — resolves the `defaultLayoutId` setting → `JournalLayout?`.
    Returns `null` when the setting is unset, or when the id is set but
    the layout was deleted (orphan id).
  - `countCustomCarouselUsage(definitionId)` — counts layout block slots
    whose `customCarousel` template points at a custom block definition.
    Used by Block Settings delete confirmation so users see whether a
    definition is still present in any layouts.
  - `countWannadoUsage(definitionId)` — counts `SectionKind.wannado`
    **sections** whose `LayoutSection.definitionId` matches (GUS-42/
    GUS-45). Unlike custom carousels (config on a block template), a
    wanna-do carousel attaches to the section itself. Used by the Block
    Settings wanna-do delete confirmation.
  - `setDefault(id)` — async write to settings.
  - **`delete(id)` clears the default-id setting if the deleted layout
    was the default.** Otherwise next entry-create would resolve to
    an orphan id and silently fall through to "no default" → empty
    entry. This invariant matters; don't refactor it away.
  - `seedDefaultIfEmpty()` — first-launch bootstrap. If the box is
    empty, creates a "Default" layout of kind `LayoutKind.custom`
    with two sections: a 4-slot `blockGrid` (`rows: 2`, four
    `textBlock` templates) followed by a full-width `text` section.
    Marks it as default. **`custom` is deliberate** — it's the only
    reorderable kind, so users can drag-rearrange the four blocks in
    their journal entries. `LayoutKind.fixedFourPlusText` looks
    superficially similar but is structurally locked and would block
    in-entry drag-drop. If the box is non-empty but no default is set
    (e.g. the user deleted the previously-default), adopts the first
    layout.
  - `deleteAllLayouts()` — destructive bulk delete used by the
    debug menu. Deletes every layout, clears the default-id setting,
    then calls `seedDefaultIfEmpty()` so the user is never stranded
    without a layout. Returns the number of deleted layouts
    (excludes the freshly-seeded default).

## Implementation details

- **Single source of truth.** `JournalRepository` is the only thing
  that calls into `HiveStorageService`, and `AuthRepository` is the
  only thing Profile uses for auth state/actions. View models hold a
  reference to the relevant repository and subscribe to its
  `ChangeNotifier`.
- The two repositories are independent, but `JournalRepository` holds a
  reference to `LayoutRepository` so it can resolve the user's default
  layout when materializing a new entry.
- All `debugPrint` logs are prefixed `[JournalRepository]` /
  `[LayoutRepository]` so console output for the data layer is
  greppable.

## Gotchas

- **The sweep runs on three triggers** (cold start, app resume, editor
  pop). If you add a fourth trigger (e.g. a manual "clean up" button),
  make sure it goes through this method so the `ChangeNotifier` fires
  exactly once per sweep.
- **`createEntryForDate` doesn't check for existing entries.** Calling
  it on a day that already has one will overwrite. The current callers
  (`HomeViewModel.createEntryWithLayout`,
  `JournalEntryEditorViewModel.createWithLayout`) only invoke it from
  CTAs that are only shown when no entry exists, so this is safe but
  fragile. If you add a new call site, gate it on `getEntryForDate`
  returning `null` first.
- **`getAllEntries()` is unsorted by design** — pushing sort into the
  repo would mean choosing an order that suits one caller but not
  others. Each VM sorts the way it wants.
- **Empty layouts produce empty entries.** `_blocksFromLayout` returns
  `const []` for a null layout or `layout.blocks.map(...).toList()`
  otherwise. The editor's "Make entry" CTA only renders when there
  *is* a layout to pick, but a deep-linked entry could end up empty
  if every layout was deleted between picker open and create. Not
  currently guarded — handle if it ever bites.

## When to update this file

- A new public method is added to either repository.
- The notification contract changes (e.g. partial-write notifications,
  per-entry notifications) — every VM subscribes to this, document it.
- The default-layout-on-delete invariant changes.
- A new sweep trigger is wired in.
