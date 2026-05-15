# lib/ui/blocks/location_block — Location (map) block widget

One `BlockType.locationBlock` block. Stores a single latitude/longitude
pair captured by long-pressing on a map. Content shape:
`{"latitude": 51.5, "longitude": -0.12}` (both keys omitted when no pin
is dropped). Typed wrapper:
[LocationBlockContent](../../../data/model/block_content/location_block_content.dart).

Backed by `flutter_map` (MIT, pure Dart) rendering OpenStreetMap tiles.
No API key required. The user-agent set on `TileLayer` identifies the
app per the OSM tile policy.

## Files

- [location_block_widget.dart](location_block_widget.dart) —
  `LocationBlockWidget`. Stateful — owns the `MapController` so panning
  / zooming state survives rebuilds.

## Modes

- `BlockMode.readOnly`:
  - No pin → dimmed em-dash placeholder.
  - Pin set → `FlutterMap` with `InteractiveFlag.none` (no panning),
    centred on the pin at zoom 13, with a single `Marker` rendered as
    `PhosphorIconsFill.mapPin`.
- `BlockMode.editable`:
  - No pin → world-level `FlutterMap` (`LatLng(20, 0)`, zoom 1.5) with
    a translucent overlay strip at the bottom reading
    "Long-press to drop a pin".
  - Pin set → recentres on the pin at zoom 13; the user can long-press
    elsewhere to move the pin (overwrites the saved coordinates).
  - Interaction flags: drag + pinchZoom + doubleTapZoom + scrollWheelZoom.
    Rotation is off (it doesn't add value at block-tile size and the
    block grid never rotates).

## How the pin write works

`MapOptions.onLongPress: (TapPosition tap, LatLng point) => …`
forwards the world-coordinate of the long-press into a fresh
`JournalBlockData` via `widget.onChanged`. The repository update
notification rebuilds the widget; `didUpdateWidget` then calls
`MapController.move(newPin, zoom)` inside a post-frame callback so the
map recentres on the new pin. Don't move that into the synchronous
build path — the controller isn't attached during build.

## Permissions

No runtime permission is needed for the map itself — OSM tiles are
fetched over HTTPS. The block does **not** call `geolocator`. The
existing `INTERNET` permission (already declared in
[AndroidManifest.xml](../../../../android/app/src/main/AndroidManifest.xml))
is the only requirement on Android. iOS has no equivalent gate.

If a future iteration adds "center on my current location" or similar,
reuse the `geolocator` plumbing already wired for the weather API
block — see [weather_api/CLAUDE.md](../weather_api/CLAUDE.md).

## Gotchas

- **Empty-when-no-pin** — `JournalBlockEmptiness` treats a pinless
  location block as empty, so a location-block-only entry that the
  user opened-and-abandoned will be swept on the next day.
- **OSM tile-server policy** — the `TileLayer` sets
  `userAgentPackageName: 'com.example.journaling_app_rewrite'`. If the
  bundle id ever changes, update this too — OSM may block requests
  with a generic user-agent under load.
- **Block tiles are small** (one cell of the 2-column grid). The map
  renders inside a `ClipRRect(borderRadius: 6)` so the tiles don't
  bleed past the `BlockCard`'s rounded corners.

## When to update this file

- Tile provider changes (e.g. switch to MapTiler / Mapbox / Stadia).
- The interaction surface changes (e.g. tap-to-drop, drag-handle).
- A current-location button or similar geolocator integration is added.
