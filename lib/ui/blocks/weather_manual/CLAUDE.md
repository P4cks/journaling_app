# lib/ui/blocks/weather_manual — Manual weather block widget

One `BlockType.weatherManual` block. Content shape: `{"conditionId": "sun"}`
(absent → no condition selected). Typed wrapper:
[WeatherBlockContent](../../../data/model/block_content/weather_block_content.dart).

The user picks today's weather manually from a curated set of Phosphor
icons. The API-backed companion (`BlockType.weatherApi`) is a separate
block planned for a later phase — it reuses the same icon mapping.

## Files

- [weather_manual_widget.dart](weather_manual_widget.dart) — `WeatherManualWidget`.
  Stateless. Decodes `WeatherBlockContent`, renders the centred icon in
  `BlockMode.readOnly`, otherwise delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)
  which owns the PageController, expand/collapse state, and timer.
  Also exposes the top-level `weatherIconFor(conditionId, {required selected})`
  helper so the API weather block can reuse the same icon mapping. The
  body is wrapped in [BlockWithTitle](../widgets/block_with_title.dart)
  reading `BlockSettings.weatherTitle` via a `ListenableBuilder` —
  same shape as the mood block.

## Modes

- `BlockMode.readOnly` — large filled Phosphor icon centred in the cell.
  Falls back to a dimmed em-dash placeholder when `conditionId == null`.
- `BlockMode.editable` — delegates to
  [CollapsibleCarouselBlock](../widgets/collapsible_carousel_block.dart)
  with `options: weatherConditionIds`. With a selection: starts
  collapsed (centred filled icon); tapping expands a horizontal
  `PageView` over the 7 conditions. **With no selection**: starts
  already-expanded so every condition is visible at the duotone +
  dimmed style and the user can swipe to commit straight away —
  same always-expanded-when-empty contract as the mood block. The
  shared widget's collapse timer fires 1500 ms after **expand** and
  on every page change.

## Condition ids → icons

| id              | duotone (unselected) | fill (selected)     |
|-----------------|----------------------|---------------------|
| `sun`           | `sun`                | `sun`               |
| `partly_cloudy` | `cloudSun`           | `cloudSun`          |
| `cloud`         | `cloud`              | `cloud`             |
| `rain`          | `cloudRain`          | `cloudRain`         |
| `thunderstorm`  | `cloudLightning`     | `cloudLightning`    |
| `snow`          | `snowflake`          | `snowflake`         |
| `fog`           | `cloudFog`           | `cloudFog`          |

Unknown ids fall back to `PhosphorIconsDuotone.question` (defensive — should never render in practice since `WeatherBlockContent.fromMap` filters unknown ids).

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
