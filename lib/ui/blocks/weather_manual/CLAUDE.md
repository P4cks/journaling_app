# lib/ui/blocks/weather_manual — Manual weather block widget

One `BlockType.weatherManual` block. Content shape: `{"conditionId": "sun"}`
(absent → no condition selected). Typed wrapper:
[WeatherBlockContent](../../../data/model/block_content/weather_block_content.dart).

The user picks today's weather manually from a curated set of
HugeIcons stroke-rounded glyphs. The API-backed companion
(`BlockType.weatherApi`) is a separate block planned for a later
phase — it reuses the same icon mapping.

## Files

- [weather_manual_widget.dart](weather_manual_widget.dart) — `WeatherManualWidget`.
  Stateless. Thin wrapper around
  [CarouselBlockScaffold](../widgets/carousel_block_scaffold.dart)`<String>`:
  decodes `WeatherBlockContent.conditionId`, supplies
  `weatherConditionIds` as the options list, and renders each option
  as an `AppIcon(weatherIconFor(id, selected: isSelected), size: 64)`.
  Also exposes the top-level `weatherIconFor(conditionId, {required selected})`
  helper so the API weather block can reuse the same icon mapping.
  The hardcoded title `"Today's weather"` is gated by
  `BlockSettings.carouselTitlesEnabled` (read via a `ListenableBuilder`
  on `BlockSettings`). The scaffold owns the read-only em-dash
  placeholder, the focus animation, and the `BlockWithTitle` wrap.
  Same shape as the mood block — the title text is fixed
  per-block-type, not user-editable.

## Modes

- `BlockMode.readOnly` — large HugeIcons stroke glyph centred in the cell.
  Falls back to a dimmed em-dash placeholder when `conditionId == null`.
- `BlockMode.editable` — delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)
  with `options: weatherConditionIds`. With a selection: starts
  collapsed (centred glyph); tapping expands a horizontal
  `PageView` over the 7 conditions. **With no selection**: starts
  already-expanded so every condition is visible at the dimmed style
  and the user can swipe to commit straight away — same
  always-expanded-when-empty contract as the mood block. The shared
  widget's collapse timer fires 1500 ms after **expand** and on every
  page change.

## Condition ids → icons

`weatherIconFor` returns the same HugeIcons stroke-rounded glyph for
both selected and unselected states (the free HugeIcons package ships
only one stroke variant — selection is communicated via colour). The
`selected` parameter is retained for call-site compatibility but
ignored in the switch body.

| id              | HugeIcons glyph              |
|-----------------|------------------------------|
| `sun`           | `strokeRoundedSun01`         |
| `partly_cloudy` | `strokeRoundedSunCloud01`    |
| `cloud`         | `strokeRoundedCloud`         |
| `rain`          | `strokeRoundedCloudMidRain`  |
| `thunderstorm`  | `strokeRoundedCloudAngledZap`|
| `snow`          | `strokeRoundedSnow`          |
| `fog`           | `strokeRoundedCloudFastWind` |

Unknown ids fall back to `HugeIcons.strokeRoundedQuestion` (defensive — should never render in practice since `WeatherBlockContent.fromMap` filters unknown ids).

## Gotchas

- **Persisted ids are strings, not indices.** Reordering `weatherConditionIds`
  is safe for existing entries; removing an id means existing entries
  that stored it decode as "no condition" (per `fromMap`'s membership
  check).
- **`weatherIconFor` is exported** for the future API weather block.
  Don't inline it back into the widget.
- **Expanded state fires `onInteractionLockChanged(blockId, true)`** via
  `CollapsibleCarouselBlock` so `JournalPager` swaps to
  `NeverScrollableScrollPhysics`. The release lives inside the shared
  widget; this block doesn't have its own dispose path. See
  [widgets/CLAUDE.md](../widgets/CLAUDE.md) for the full lifecycle.

## When to update this file

- A weather condition id is added or removed.
- The icon mapping for an existing id changes.
- The carousel mechanic changes.
