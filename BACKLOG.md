# Backlog

Running list of feature ideas. Not prioritized — pick whichever fits the moment.
Tick `[x]` when shipped (link the PR). Add new ideas at the bottom of the relevant section, or create a new section if nothing fits.

## UX / structure
- [ ] **Refactor profile page to be more organised** — current screen mixes Appearance, Layouts, and Debug in a flat `ListView`. Move settings off Profile into a **dedicated Settings page** accessible from a Profile row (`Profile → Settings →`). The Settings page itself uses **collapsible/toggleable sections** — Appearance (expanded by default) and Debug (collapsed by default, ideally hidden behind a discovery toggle so casual users don't see the override pickers). Layouts likely stays on Profile (or moves into Settings as its own row — TBD when implementing).
- [ ] **Drop the explicit edit toggle in the journal-entry editor** — for editable days, blocks should be directly editable. No pencil button, no read/edit mode toggle. Past days still need the read-only lock.
- [ ] **Layouts: assign an icon to each layout** — Phosphor icon picker; the chosen icon shows up in the layout-picker sheet and on the Layouts list rows. Also: layout title editing should match the same tap-to-edit pattern used for journal-entry titles.
- [ ] **Better affordance for tap-to-edit titles** — the current "tap the title to edit" pattern (entries today, layouts later) is invisible. Hint: a faint underline, a subtle pencil glyph next to the text, or a one-time tooltip on first launch.

## Theming / typography
- [ ] **Revisit the surface palette system** — let users build and save their own palettes end-to-end (surface tint + secondary + accent), persisted alongside the existing curated list. Reduce the number of built-in defaults; lean on user-defined slots.
- [ ] **Choose a new font** — currently the platform default. Pick something with more character for a journaling app (e.g. Lora, Source Serif, Inter — TBD).

## Widget / block ideas
- [ ] **Todo block** — checkable list items inside an entry.
- [ ] **Text block: character limit** — optional/configurable cap on the text block to encourage brevity.
- [ ] **Weather block (manual)** — user picks a weather icon for the day (Phosphor sun, cloud, raindrops, snowflake, etc.).
- [ ] **Weather block (API)** — fetches weather by location for the entry's date. Needs a weather provider and probably a location-permission flow.
- [ ] **Quote of the day (API)** — fetches a daily quote from a public API; non-editable display.
- [ ] **Prompt block** — configurable text block that displays a question above the input ("What surprised you today?"); the user answers in the field.

## Subscription / monetization
- [ ] **Subscription scaffolding** — feature-gating infrastructure that scales to multiple tiers (e.g. free / pro / pro+). Tier capability flags read from a single source so individual gates are one-liners.
- [ ] **Gate: free users limited to 1 layout** — paid tiers unlock unlimited.
- [ ] **Gate: cloud synchronization (paid only)** — accounts + sync backend (separate piece of work).
- [ ] **Gate: block count per layout for free users** — paid tiers unlock more blocks per layout (or unlimited).

<!-- Add new ideas at the bottom of the appropriate section, or create a new section. -->
