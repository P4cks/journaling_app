# Backlog

Running list of feature ideas. Not prioritized — pick whichever fits the moment.
Tick `[x]` when shipped (link the PR). Add new ideas at the bottom of the relevant section, or create a new section if nothing fits.

**Complexity legend:** `S` small (≤2h, isolated) · `M` medium (half-day to day, multiple files) · `L` large (multi-day, new patterns/data model) · `XL` extra-large (infrastructure, requires architectural decisions)

## UX / structure

- [ ] `L` **Refactor profile page to be more organised** — current screen mixes Appearance, Layouts, and Debug in a flat `ListView`. Move settings off Profile into a **dedicated Settings page** accessible from a Profile row (`Profile → Settings →`). The Settings page itself uses **collapsible/toggleable sections** — Appearance (expanded by default) and Debug (collapsed by default, ideally hidden behind a discovery toggle so casual users don't see the override pickers). Layouts likely stays on Profile (or moves into Settings as its own row — TBD when implementing).
- [x] **Drop the explicit edit toggle in the journal-entry editor** ([#11](https://github.com/P4cks/journaling_app/pull/11)) — for editable days, blocks render directly editable. Pencil button and read/edit mode toggle removed. Past days still show the read-only lock.
- [x] **Layouts: assign an icon to each layout** ([#11](https://github.com/P4cks/journaling_app/pull/11)) — curated Phosphor icon picker in the layout editor; the chosen icon renders in the Layouts list (default layout's badge in `primaryContainer` so it still reads as primary) and in the layout-picker sheet.
- [ ] `S` **Layouts: tap-to-edit name in the editor** — match the inline AppBar tap-to-edit pattern used for journal-entry titles instead of the current always-visible TextField.
- [ ] `S` **Better affordance for tap-to-edit titles** — the current "tap the title to edit" pattern (entries today, layouts later) is invisible. Hint: a faint underline, a subtle pencil glyph next to the text, or a one-time tooltip on first launch.
- [ ] `S` **Remove ripple effect when opening a journal entry** — replace with a softer or no-touch feedback to better match the calm journaling feel.
- [ ] `S` **Rename Home tab to Journal** — clearer mental model; aligns with core feature.
- [ ] `M` **Preview of block when adding block** — the add-block menu should expand to the whole screen and show a preview of the block (with the title below) before inserting it.
- [ ] `S` **Turn "Add block" button into small plus** — and remove the "Blocks" title.
- [ ] `M` **Split entry into block and text section.**

## Theming / typography

- [ ] `L` **Revisit the surface palette system** — let users build and save their own palettes end-to-end (surface tint + secondary + accent), persisted alongside the existing curated list. Reduce the number of built-in defaults; lean on user-defined slots.
- [ ] `S` **Choose a new font** — currently the platform default. Pick something with more character for a journaling app (e.g. Lora, Source Serif, Inter — TBD).
- [ ] `M` **Toggle between emoji and Phosphor icons for blocks** — let users switch between emojis and Phosphor icons.

## Widget / block ideas

- [ ] `M` **Todo block** — checkable list items inside an entry.
- [ ] `S` **Text block: character limit** — optional/configurable cap on the text block to encourage brevity.
- [ ] `L` **Variable-sized blocks** — allow certain blocks (starting with text) to expand dynamically based on content instead of fixed height.
- [ ] `S` **Weather block (manual)** — user picks a weather icon for the day (Phosphor sun, cloud, raindrops, snowflake, etc.).
- [ ] `L` **Weather block (API)** — fetches weather by location for the entry's date. Needs a weather provider and probably a location-permission flow.
- [ ] `M` **Quote of the day (API)** — fetches a daily quote from a public API; non-editable display.
- [ ] `S` **Prompt block** — configurable text block that displays a question above the input ("What surprised you today?"); the user answers in the field.
- [ ] `S` **Mood block** — center it more and remove the text label.
- [ ] `XL` **Calendar integration block** — display activities for the day.
- [ ] `M` **Memory block** — show a random block from a past day (with date and link to the entry).
- [ ] `L` **Photo block** — add or take a photo to attach to that day.

## Entries tab ideas

- [ ] `M` **Highlights / memories** — surface past entries ("On this day last year…").
- [ ] `L` **Entry analytics** — simple insights (most used words, mood trends).

## Profile implementation

- [ ] `XL` **Profile implementation with Firebase**

## Subscription / monetization

- [ ] `XL` **Subscription scaffolding** — feature-gating infrastructure that scales to multiple tiers (e.g. free / pro / pro+). Tier capability flags read from a single source so individual gates are one-liners. Using a tool like RevenueCat.
- [ ] `S` **Gate: free users limited to 1 layout** — paid tiers unlock unlimited. (requires scaffolding)
- [ ] `XL` **Gate: cloud synchronization (paid only)** — accounts + sync backend (separate piece of work).
- [ ] `S` **Gate: block count per layout for free users** — paid tiers unlock more blocks per layout (or unlimited). (requires scaffolding)
- [ ] `S` **Gate: statistics and insight (paid only).** (requires scaffolding)
- [ ] `M` **Gate: limited selection of blocks for free users** — set some default blocks (text, mood, etc.); maybe let users select one as a gift after a 7-day streak.
- [ ] `S` **Gate: change theme (paid only)** — custom themes only configurable as a paid user. Free users get the default theme only.

<!-- Add new ideas at the bottom of the appropriate section, or create a new section. -->
