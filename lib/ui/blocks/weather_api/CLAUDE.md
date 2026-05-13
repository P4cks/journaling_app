# lib/ui/blocks/weather_api — API-backed weather block widget

One `BlockType.weatherApi` block. Auto-fetches current weather via
[WeatherService](../../../data/services/weather_service.dart) using
the device's location, then bakes the result into the entry's content.
Content shape:
`{"conditionId": "...", "temperatureC": 12.4, "fetchedDate": "yyyy-MM-dd"}`.
Typed wrapper: [WeatherApiBlockContent](../../../data/model/block_content/weather_api_block_content.dart).

## Files

- [weather_api_widget.dart](weather_api_widget.dart) —
  `WeatherApiWidget`. Stateful — owns the in-flight + failure-status
  flags.

## Fetch lifecycle

- **First build with empty content** → calls
  [`WeatherService.getCurrentWeather`](../../../data/services/weather_service.dart),
  which: checks the day-keyed cache in the `settings` Hive box; on
  miss, requests location permission, gets a coarse `Position`, calls
  Open-Meteo `/v1/forecast?current_weather=true`, maps the `weathercode`
  to a condition id from the same set as the manual weather block.
- **On success** → emits a new `JournalBlockData` with the condition,
  temperature, and fetched date baked in. Subsequent rebuilds read the
  stored snapshot; re-opening the entry never refetches.
- **Failure states** (separate via `WeatherFetchStatus`):
  - `permissionDenied` → "Enable location" + Grant button (calls back
    into `getCurrentWeather`, which re-requests permission).
  - `locationDisabled` → "Location services are off" + Retry.
  - `networkFailure` → "Couldn't fetch weather" + Retry.

## Modes

The widget renders identically in `readOnly` and `editable` (not
user-editable). When data is present: large Phosphor icon (via the
shared [`weatherIconFor`](../weather_manual/weather_manual_widget.dart)
helper) + temperature in °C below. Otherwise: loading spinner, or the
appropriate failure message + retry.

## Permissions

Required platform manifest entries (already present):

- iOS [`Info.plist`](../../../../ios/Runner/Info.plist) —
  `NSLocationWhenInUseUsageDescription`.
- Android [`AndroidManifest.xml`](../../../../android/app/src/main/AndroidManifest.xml) —
  `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `INTERNET`.

## Gotchas

- **Don't bake fetch failures into content.** The widget only emits an
  `onChanged` on success, so transient network or permission failures
  don't poison the entry — the user can retry on the next open.
- **Cache buckets by `~10 km`** (lat/lon rounded to 1 decimal), so
  two entries created in the same city the same day share one HTTP
  round-trip.
- **Empty-when-unfetched** — a `weatherApi`-only entry that never
  successfully fetched will be swept on the next day.

## When to update this file

- Different weather provider / endpoint.
- The weathercode → conditionId mapping changes (also update the manual
  weather mapping in `weather_manual_widget.dart`).
- Adding background refresh or refresh-on-tap behavior.
