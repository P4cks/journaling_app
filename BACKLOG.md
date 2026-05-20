# Backlog

Running list of feature ideas. Not prioritized — pick whichever fits the moment.
Add a complexity measure to the idea
Tick `[x]` when shipped (link the PR). Add new ideas at the bottom of the relevant section, or create a new section if nothing fits.

READ CLAUDE.md for further implementation details

**Complexity legend:** `S` small (≤2h, isolated) · `M` medium (half-day to day, multiple files) · `L` large (multi-day, new patterns/data model) · `XL` extra-large (infrastructure, requires architectural decisions)

## UX / structure

* [x] `L` **Refactor profile page to be more organised** — current screen mixes Appearance, Layouts, and Debug in a flat `ListView`. Move settings off Profile into a **dedicated Settings page** accessible from a Profile row (`Profile → Settings →`). The Settings page itself uses **collapsible/toggleable sections** — Appearance (expanded by default) and Debug (collapsed by default, ideally hidden behind a discovery toggle so casual users don't see the override pickers). Layouts likely stays on Profile
* [x] **Drop the explicit edit toggle in the journal-entry editor** ([#11](https://github.com/P4cks/journaling_app/pull/11)) — for editable days, blocks render directly editable. Pencil button and read/edit mode toggle removed. Past days still show the read-only lock.
* [x] **Layouts: assign an icon to each layout** ([#11](https://github.com/P4cks/journaling_app/pull/11)) — curated Phosphor icon picker in the layout editor; the chosen icon renders in the Layouts list (default layout's badge in `primaryContainer` so it still reads as primary) and in the layout-picker sheet.
* [x] `S` **Layouts: tap-to-edit name in the editor** — match the inline AppBar tap-to-edit pattern used for journal-entry titles instead of the current always-visible TextField.
* [x] `S` **Better affordance for tap-to-edit titles** — the current "tap the title to edit" pattern (entries today, layouts later) is invisible. Hint: a faint underline, a subtle pencil glyph next to the text, or a one-time tooltip on first launch.
* [x] `S` **Remove ripple effect when opening a journal entry** — replace with a softer or no-touch feedback to better match the calm journaling feel.
* [x] `S` **Rename Home tab to Journal** — clearer mental model; aligns with core feature.
* [x] `M` **Preview of block when adding block** - the add block menu should expand to half the screen and show a preview of the block (with the title below) before inserting it
* [x] `S` **turn "Add block" button into small plus** - and remove Blocks title
* [x] `M` **Different layout options** - Add other "layout strategies", like only blocks (already implemented) or alternatively an overarching section layout where you can layout the page into block sections of different sizes (which also makes it easy to implement bigger style blocks) and text sections, these sections would then be layed out in a horizontal style
* [x] `S` **Remove checkmark from layouteditor** - remove checkmark icon button and replace it by automatic save on exit, with a popup asking you to save or discard the new layout before leaving the editor (eg. routing to another page)
* [x] `M` **Implement swipe gestures** - implement swipe gestures for navigating (especially going back)
* [x] `S` **Complete Layout Preview** - Preview should be in layout
* [x] `S` **Modal editing mode** — while a block (or the title) is being edited, the AppBar collapses to a single Done button and the swipe pager is locked, so editing can't accidentally navigate away. Tapping Done unfocuses the TextField. Driven off `WidgetsBindingObserver.didChangeMetrics` on `MainJournalScreen` (MediaQuery.viewInsetsOf inside the body returns 0 due to Scaffold's `resizeToAvoidBottomInset`). AppBar actions also unfocus before AND after navigation in the non-modal path to defend against Flutter's focus auto-restoration.
* [x] `M` **Choose-layout sheet — half-screen scrollable** — `showLayoutPickerSheet` reworked to use the same `DraggableScrollableSheet` pattern as `showAddBlockSheet`, so long layout lists scroll inside the sheet instead of pushing the AppBar off-screen.
* [x] `M` **Replace Phosphor icons with HugeIcons** — swapped `phosphor_flutter` for the free `hugeicons` package (stroke-rounded family only — selection state now driven by colour). Centralised `AppIcon` rewrapped around `HugeIcon`; `secondaryColor` / `secondaryOpacity` props dropped. Curated `LayoutIcon` / `CarouselIcon` catalogues collapsed to a single `icon` field; persisted `name` ids retained so saved layouts and carousel picks still resolve. Closest-match substitutions documented inline in the catalogues.

## Theming / typography

* [x] `L` **Revisit the surface palette system** — let users build and save their own palettes end-to-end (surface tint + secondary + accent), persisted alongside the existing curated list. Reduce the number of built-in defaults; lean on user-defined slots. Also let them chose a fontcolor
* [ ] `S` **Choose a new font** — currently the platform default. Pick something with more character for a journaling app (e.g. Lora, Source Serif, Inter — TBD).
* [ ] `M` **Toggle between emoji and HugeIcons for blocks** — let users switch between emojis and HugeIcons stroke-rounded glyphs.
* [ ] `L` **Animations** - rework animations for navigation to be smoother and visually appealing but discrete/
* [ ] `S` **Change shadows on boxes**

## Section ideas

* [ ] `M` **2-up row section** — locked 2×1 row of two 1×1 blocks side by side (no add/remove), available inside custom layouts.
* [ ] `L` **Banner section** — full-width 2×1 rectangular block (half the height of a featureBlock) for weather/quote/mood headers.
* [ ] `L` **Header + body section** — a single 1×1 block pinned next to a multi-line text area (asymmetric block + text combo).
* [ ] `XL` **Per-section background color** — let custom-layout sections pick a tint to visually group blocks on long entries.

## Widget / block ideas

* [x] `M` **Todo block** — checkable list items inside an entry. Items are per-entry (no layout template); add/toggle/delete inline; sweep-empty when every item has empty-after-trim text.
* [ ] ~~`S` **Text block: character limit**~~ — shipped briefly, then removed. Block-type-global cap proved unwanted complexity; text blocks now have no per-type-global settings.
* [x] `M` **Feature block section (2×2 single block)** — new `SectionKind.featureBlock` available inside custom layouts. Holds exactly one block at 2×2 (full-width square), restricted to photo or memory in the layout editor. Memory block also gained photo support: it can now snapshot photos from past entries (1×1 or 2×2) and render them as cropped thumbnails. Replaces the earlier "text expanding dynamically" framing — content-driven expansion is deferred.
* [x] `S` **Weather block (manual)** — user picks a weather icon for the day (Phosphor sun, cloud, raindrops, snowflake, etc.). Carousel of 7 conditions (`sun`, `partly_cloudy`, `cloud`, `rain`, `thunderstorm`, `snow`, `fog`); icon mapping shared with the future API weather block.
* [x] `L` **Weather block (API)** — fetches weather by location for the entry's date. Open-Meteo + `geolocator`; permission-denied / network-failure / location-disabled states surface with retry. Caches per-day per-location in the settings box; icon mapping shared with the manual weather block.
* [x] `M` **Quote of the day (API)** — fetches a daily quote from a public API; non-editable display. ZenQuotes `/api/today`, cached per-day in the settings box; on first build the block fetches and bakes the quote/author into the entry's content forever.
* [x] `S` **Prompt block** — configurable text block that displays a question above the input ("What surprised you today?"); the user answers in the field. New `BlockType.promptBlock`; prompt list + strategy (`daily` / `random`) configured globally in Profile → Block settings → Prompt block; the chosen prompt is baked into each new entry at materialization time.
* [x] `S` **Mood block** - center it more and remove text. Replaced 3-Phosphor-icon ChoiceChip row with a swipeable emoji carousel (😄 😊 😌 😐 😢 😠 😩 😍 🤔). Schema-tolerant: legacy `moodId` values still decode (happy→😄, neutral→😐, sad→😢).
* [ ] `XL` **Integration Calender block** - display activities for the day
* [ ] `S` **Gratitude block** — three short input lines.
* [ ] `M` **Habit tracker block** — fixed list of habits with check-off, per-day state.
* [ ] `S` **Sleep block** — hours numeric + optional quality emoji.
* [ ] `S` **Water/hydration counter block** — tap-to-increment with a daily target.
* [ ] `M` **Voice note block** — record a short clip; store under `<docs>/audio/<uuid>.<ext>` mirroring photo storage.
* [ ] `S` **Reading log block** — book title + page number.
* [ ] `M` **Drawing block** — small canvas, save as png in the photo storage dir.
* [ ] `S` **Three highlights block** — three short bullet lines.
* [ ] `S` **Daily affirmation block** — user-defined pool, picked daily (like quote block, but local).
* [ ] `S` **Tag/cluster block** — pick from a configurable list of tags ("work", "social", "exercise"…).
* [ ] `M` **Spending block** — amount + category for one-off expense tracking.
* [x] `M` **Memory block** - show random block from a past day (with date and link to the entry). Picks once from any non-empty text or mood block in past entries, locks the snapshot into the entry's content, tap-to-navigate to source.
* [x] `L` **Photo block** - add or take a foto to add to that day. `image_picker` (camera/gallery); files copied to `<docs>/photos/<uuid>.<ext>` with the path stored in content. Long-press → Replace / Remove. iOS + Android permission strings wired.
* [x] `L` **Custom carousel block** — user-defined carousel "types" with a title + ordered list of emoji/icon items, created from the layout editor's Add-Block sheet via "Add custom block" → editor screen. Definitions live in a `BlockSettings` registry; referenced by id from layout templates and entry blocks, so edits propagate live to every existing instance. Selections stored verbatim (survives item reorders). Deletion is cascade-tolerant — orphan blocks render a "Deleted block" placeholder. Mood and manual-weather carousels gained an optional title from the same Block-Settings screen, which is now a single inline save-on-leave page (no more per-type sub-screens). Plus debug-menu Delete all entries / Delete all layouts (the latter re-seeds the default).
* [ ] `S` Weather api placeholder should have a location exampl

## Entries tab ideas

* [ ] `M` **Highlights / memories** — surface past entries (“On this day last year…”).
* [~] `L` **Entry analytics** — initial Statistics page shipped (streak, summary numbers, mood distribution, mood-over-time line, weekly frequency, range selector). Future: word-frequency / most-used-words insights, GitHub-style heatmap, year-in-review summary.

## Profile implementation

* [x] `L` **Firebase Auth profile scaffold** — optional Profile sign-in with email/password, Google, and Apple through a Firebase Auth repository boundary. No journaling features are gated and no local Hive data is synced yet.
* [x] `S` **Dedicated Profile screen + dropdown rework** — `/profile` reachable from the journal-AppBar profile dropdown. When signed out, the dropdown shows a "Sign in" row that pushes `/profile` (Email / Google / Apple via the existing `ProfileAuthCard`). When signed in, the dropdown shows the user's name or email plus a "Sign out" row guarded by a confirm dialog. When `authRepository.isConfigured == false` (Firebase init failed) both rows are suppressed so the dropdown stays local-journaling-only.
* [ ] `M` **Apple Sign In after Enrollment in Apple Developer Program** — UI is wired (Apple button on `/profile`); needs the entitlement / provisioning before it succeeds at runtime.
* [ ] `XL` **Profile implementation with firebase Firestore/Storage** — add cloud profile data, storage-backed avatar/media, and eventual sync once the auth-only scaffold is stable.

## Subscription / monetization

* [ ] `XL` **Subscription scaffolding** — feature-gating infrastructure that scales to multiple tiers (e.g. free / pro / pro+). Tier capability flags read from a single source so individual gates are one-liners. Using a tool like revenuecat
* [ ] `S` **Gate: free users limited to 1 layout** — paid tiers unlock unlimited. (requires scaffolding)
* [ ] `XL` **Gate: cloud synchronization (paid only)** — accounts + sync backend (separate piece of work).
* [ ] `S` **Gate: block count per layout for free users** — paid tiers unlock more blocks per layout (or unlimited). (requires scaffolding)
* [ ] `S` **Gate: statistics and insight (paid only)** - (requires scaffolding)
* [ ] `M` **Gate: limited selection of blocks for free users** - set some default blocks, text block, mood block etc. maybe let user select one as a gift after 7 day streak
* [ ] `S` **Gate: change theme (paid only)** - custom themes only configurable as a paid user. For free users only default theme
* [ ] `S` **Gate: differently styled layouts** - restrict free users to 4 blocks followed by one text section or something along those lines, paid users can choose to have only blocks or customize sections
* [ ] `S` **Paywall or grey out locked features (TBD)**
* [ ] `S` **
