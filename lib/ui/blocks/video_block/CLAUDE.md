# lib/ui/blocks/video_block — Video block widget

One `BlockType.videoBlock` block (GUS-16, PRO). Fills the 1×1 cell with
a short clip's poster frame. Content shape:
`{"videoPath": "/.../video/<uuid>.mp4", "durationMs": 8200}`. Typed
wrapper: [VideoBlockContent](../../../data/model/block_content/video_block_content.dart).

Modelled on the [photo block](../photo_block/CLAUDE.md) — read that first;
the picker / storage / cleanup contract is identical, with `pickVideo`
and a `VideoStorageService` substituted for the image equivalents.

## Files

- [video_block_widget.dart](video_block_widget.dart) — `VideoBlockWidget`
  (stateless dispatcher target) plus three private pieces:
  - top-level `fireVideoBlockAction(context, data, onChanged)` — the
    single-sourced action, mirroring `firePhotoBlockAction`. Empty →
    source sheet; filled → Play / Replace / Remove sheet.
  - `_VideoPoster` — stateful; holds a `VideoPlayerController` only long
    enough to paint frame 0 (paused) as a `BoxFit.cover` poster, with a
    play glyph overlay + duration badge.
  - `_FullscreenVideoPlayer` — fullscreen-dialog route pushed by Play;
    auto-plays, tap toggles play/pause, `VideoProgressIndicator` scrubs.

## States and modes

| Mode + state | Render |
|---|---|
| `editable`, no video | "+ Add video" affordance; tap → Record/Library sheet. |
| `editable`, has video | Poster frame + play glyph + duration badge; top-right `⋯` [`BlockOptionsButton`](../widgets/block_options_button.dart) → Play/Replace/Remove sheet; double-tap → expanded route (tap there fires the action). **Long-press is NOT handled** so it falls through to `BlockGrid`'s drag-to-reorder (GUS-76). |
| `readOnly`, no video | Dimmed italic "No video" placeholder. |
| `readOnly`, has video | Poster frame; tap plays fullscreen. |

## Storage contract

Never stores bytes in Hive — only the absolute path. Picked clips are
copied into the app documents directory via
[`VideoStorageService.savePickedFile`](../../../data/services/video_storage_service.dart),
which writes to `<docs>/video/<uuid>.<ext>` (whitelist `.mp4/.mov/.m4v`,
fallback `.mp4`). Replace/Remove calls `deleteAtPath` on the previous
path so old files don't accumulate. The capture is capped at 10 s via
`pickVideo(maxDuration: Duration(seconds: 10))`.

Duration is probed **once at save time** by briefly initialising a
throwaway `VideoPlayerController` (`_readDurationMs`) and stored in
`durationMs`, so the grid cell can show the badge without keeping a
player alive.

## Permissions

- iOS [`Info.plist`](../../../../ios/Runner/Info.plist) —
  `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` (camera
  video records audio), `NSPhotoLibraryUsageDescription`.
- Android [`AndroidManifest.xml`](../../../../android/app/src/main/AndroidManifest.xml) —
  `CAMERA`, `READ_MEDIA_VIDEO`. Camera video recording is delegated to
  the system camera app (which owns the mic permission), so no app-level
  `RECORD_AUDIO` is needed for this block.

## Gotchas

- **`maxDuration` is only enforced on the camera path.** Library picks
  can exceed 10 s on some platforms — accepted as-is for v1.
- **Poster controllers are per-cell.** `_VideoPoster` initialises a
  `VideoPlayerController` for each filled cell to paint the first frame;
  it's disposed in `dispose`/`didUpdateWidget`. Typically one video
  block per entry, so this is fine — revisit if many land in one grid.
- **Missing-file fallback**: `_VideoPoster` shows a dark "Video missing"
  panel if `initialize()` throws on a stale path.
- **Entry-delete doesn't cascade to video files** — same caveat as the
  photo block. Wire `videoStorage.deleteAtPath` into
  `JournalRepository.deleteEntry` if/when programmatic entry deletion
  beyond the empty-sweep is added.
- **`VideoStorageService` is constructed in `main.dart`** and exposed via
  `AppDependencies.videoStorage`; grab it through
  `AppDependencies.of(context)`, don't instantiate a new one.

## When to update this file

- A camera-only / library-only variant is split out.
- Inline (in-grid) playback replaces the fullscreen player.
- Cascade-delete on entry removal is wired up.
