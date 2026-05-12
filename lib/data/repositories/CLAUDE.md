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
    `List<BlockTemplate>` into fresh `JournalBlockData` instances.
    Per-type seeding:
    - `promptBlock` — calls `BlockSettings.pickPromptFor(date,
      slotIndex)` to bake today's prompt into the entry's content.
      The `slotIndex` is the prompt block's ordinal among prompt
      blocks in this layout (not the overall block index), so two
      prompt blocks on the same day get different prompts under
      `daily` strategy.
    - Other types — empty content map; the widget owns its read-time
      reads (e.g. `TextBlockWidget` reads `BlockSettings.textCharLimit`
      live).
    Public so the editor's `applyLayout` path uses the same code.
  - `saveJournalEntry(entry)` — async write, notifies on completion.
  - `deleteEntry(entry)` — async delete, notifies.
  - `getAllEntries()` — unsorted; sorting is caller's job
    (`JournalEntriesViewModel` and `HomeViewModel.entriesByDay`
    each do their own).
  - `pickRandomEligibleBlock({beforeDate, eligibleTypes})` — used by
    [MemoryBlockWidget](../../ui/blocks/memory_block/memory_block_widget.dart)
    to seed itself. Iterates all entries strictly before `beforeDate`,
    filters to blocks whose `type` is in `eligibleTypes` AND whose
    `isEmpty` is false (per `JournalBlockEmptiness`), and uniformly
    samples. Returns `(date, block)` or `null` when the pool is empty.
    The caller persists the snapshot into the entry's content so the
    pick is locked.
  - `sweepEmptyPastEntries({now})` — deletes past-day entries whose
    every block is empty (per `JournalEntry.hasNoContent`). Today's
    entries are never deleted (user may still be drafting). Returns
    the count; notifies once if anything was deleted.
    **Called from three places**: `main.dart` cold-start, `MyApp`'s
    `didChangeAppLifecycleState` resume, and `HomeScreen._openEditor`
    on editor-pop.
- [layout_repository.dart](layout_repository.dart) — `LayoutRepository`.
  **Not a `ChangeNotifier`** (layout edits are infrequent and the
  Layouts screen refreshes manually on push-pop). Methods:
  - `getAll`, `getById`, `save`, `delete` — straightforward.
  - `getDefault` — resolves the `defaultLayoutId` setting → `JournalLayout?`.
    Returns `null` when the setting is unset, or when the id is set but
    the layout was deleted (orphan id).
  - `setDefault(id)` — async write to settings.
  - **`delete(id)` clears the default-id setting if the deleted layout
    was the default.** Otherwise next entry-create would resolve to
    an orphan id and silently fall through to "no default" → empty
    entry. This invariant matters; don't refactor it away.
  - `seedDefaultIfEmpty()` — first-launch bootstrap. If the box is
    empty, creates a single "Default" layout with one `textBlock` and
    marks it as default. If the box is non-empty but no default is
    set (e.g. the user deleted the previously-default), adopts the
    first layout.

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
