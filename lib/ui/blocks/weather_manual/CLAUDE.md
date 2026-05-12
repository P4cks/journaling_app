# lib/ui/blocks/weather_manual — Manual weather block widget

One `BlockType.weatherManual` block. Content shape: `{"conditionId": "sun"}`
(absent → no condition selected). Typed wrapper:
[WeatherBlockContent](../../../data/model/block_content/weather_block_content.dart).

The user picks today's weather manually from a curated set of Phosphor
icons. The API-backed companion (`BlockType.weatherApi`) is a separate
block planned for a later phase — it reuses the same icon mapping.

## Files

- [weather_manual_widget.dart](weather_manual_widget.dart) — `WeatherManualWidget`.
  Stateful — owns the `PageController` so swipe position survives rebuilds.
  Also exposes the top-level `weatherIconFor(conditionId, {required selected})`
  helper so the API weather block can reuse the same icon mapping.

## Modes

- `BlockMode.readOnly` — large filled Phosphor icon centred in the cell.
  Falls back to a dimmed em-dash placeholder when `conditionId == null`.
- `BlockMode.editable` — horizontal `PageView` of the 7 conditions
  (`weatherConditionIds` constant in [weather_block_content.dart](../../../data/model/block_content/weather_block_content.dart)).
  Selected page is full-scale + filled icon; others are duotone +
  scaled down + dimmed. `onPageChanged` writes the centred id (swiping
  to a page selects it). Same UX as the mood block carousel.

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

## When to update this file

- A weather condition id is added or removed.
- The icon mapping for an existing id changes.
- The carousel mechanic changes.
