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
* [ ] `M` **Implement swipe gestures** - implement swipe gestures for navigating (especially going back)
* [ ] `S` **Complete Layout Preview** - Preview should be in layout

## Theming / typography

* [x] `L` **Revisit the surface palette system** — let users build and save their own palettes end-to-end (surface tint + secondary + accent), persisted alongside the existing curated list. Reduce the number of built-in defaults; lean on user-defined slots. Also let them chose a fontcolor
* [ ] `S` **Choose a new font** — currently the platform default. Pick something with more character for a journaling app (e.g. Lora, Source Serif, Inter — TBD).
* [ ] `M` **Toggle between emoji and Phosphor icons for blocks** — let users switch between emojis and Phosphor icons.
* [ ] `L` **Animations** - rework animations for navigation to be smoother and visually appealing but discrete/
* [ ] `S` **Change shadows on boxes**

## Widget / block ideas

* [x] `M` **Todo block** — checkable list items inside an entry. Items are per-entry (no layout template); add/toggle/delete inline; sweep-empty when every item has empty-after-trim text.
* [x] `S` **Text block: character limit** — optional/configurable cap on the text block to encourage brevity. Configured globally in Profile → Block settings → Text block; hard cap via `TextField.maxLength` with a tiny counter overlay.
* [ ] `L` **Variable-sized blocks** — allow certain blocks (starting with text) to expand dynamically based on content instead of fixed height.
* [x] `S` **Weather block (manual)** — user picks a weather icon for the day (Phosphor sun, cloud, raindrops, snowflake, etc.). Carousel of 7 conditions (`sun`, `partly_cloudy`, `cloud`, `rain`, `thunderstorm`, `snow`, `fog`); icon mapping shared with the future API weather block.
* [x] `L` **Weather block (API)** — fetches weather by location for the entry's date. Open-Meteo + `geolocator`; permission-denied / network-failure / location-disabled states surface with retry. Caches per-day per-location in the settings box; icon mapping shared with the manual weather block.
* [x] `M` **Quote of the day (API)** — fetches a daily quote from a public API; non-editable display. ZenQuotes `/api/today`, cached per-day in the settings box; on first build the block fetches and bakes the quote/author into the entry's content forever.
* [x] `S` **Prompt block** — configurable text block that displays a question above the input ("What surprised you today?"); the user answers in the field. New `BlockType.promptBlock`; prompt list + strategy (`daily` / `random`) configured globally in Profile → Block settings → Prompt block; the chosen prompt is baked into each new entry at materialization time.
* [x] `S` **Mood block** - center it more and remove text. Replaced 3-Phosphor-icon ChoiceChip row with a swipeable emoji carousel (😄 😊 😌 😐 😢 😠 😩 😍 🤔). Schema-tolerant: legacy `moodId` values still decode (happy→😄, neutral→😐, sad→😢).
* [ ] `XL` **Integration Calender block** - display activities for the day
* [x] `M` **Memory block** - show random block from a past day (with date and link to the entry). Picks once from any non-empty text or mood block in past entries, locks the snapshot into the entry's content, tap-to-navigate to source.
* [x] `L` **Photo block** - add or take a foto to add to that day. `image_picker` (camera/gallery); files copied to `<docs>/photos/<uuid>.<ext>` with the path stored in content. Long-press → Replace / Remove. iOS + Android permission strings wired.
* [ ] `S` Weather api placeholder should have a location exampl

## Entries tab ideas

* [ ] `M` **Highlights / memories** — surface past entries (“On this day last year…”).
* [~] `L` **Entry analytics** — initial Statistics page shipped (streak, summary numbers, mood distribution, mood-over-time line, weekly frequency, range selector). Future: word-frequency / most-used-words insights, GitHub-style heatmap, year-in-review summary.

## Profile implementation

* [x] `L` **Firebase Auth profile scaffold** — optional Profile sign-in with email/password, Google, and Apple through a Firebase Auth repository boundary. No journaling features are gated and no local Hive data is synced yet.
* [ ] `M` **Apple Sign In after Enrollment in Apple Developer Program** - Apple sign in and rework Profile workflow
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
