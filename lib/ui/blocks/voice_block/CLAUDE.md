# lib/ui/blocks/voice_block — Voice block widget

One `BlockType.voiceBlock` block (GUS-12, **PRO**). Fills the 1×1 cell
with a short voice note: record a ≤60 s clip, then play it back inline.
Content shape: `{"audioPath": "/.../audio/<uuid>.m4a", "durationMs": 12345}`.
Typed wrapper: [VoiceBlockContent](../../../data/model/block_content/voice_block_content.dart).

## Files

- [voice_block_widget.dart](voice_block_widget.dart) — everything for the
  block lives here:
  - `VoiceBlockWidget` — the cell. Stateless-ish dispatcher between the
    empty affordance and the filled player.
  - `_VoicePlayer` — inline player; owns an `AudioPlayer`
    (`package:audioplayers`) + its stream subscriptions for the widget's
    lifetime.
  - `showVoiceRecorderSheet(context, storage)` + `_RecorderSheet` — the
    modal recording sheet; owns an `AudioRecorder` (`package:record`).
  - `VoiceRecording` — result value class (`path` + `durationMs`).
  - `kMaxVoiceDuration` — the 60 s hard cap (top-level const).

## States and modes

| Mode + state | Render |
|---|---|
| `editable`, no audio | "Record voice" mic affordance; tap → recording sheet. |
| `editable`, has audio | Inline `_VoicePlayer` (play/pause + progress + `m:ss / m:ss`); top-right `⋯` [`BlockOptionsButton`](../widgets/block_options_button.dart) → Re-record/Remove sheet; double-tap → expanded route. **Long-press is NOT handled** so it falls through to `BlockGrid`'s drag-to-reorder (GUS-76). |
| `readOnly`, no audio | Dimmed mic glyph (`HugeIcons.strokeRoundedMic01`) + "Voice" label, so the block is recognizable in previews like the layout editor (GUS-73) — was a bare italic "No recording". |
| `readOnly`, has audio | Inline `_VoicePlayer`. No long-press/expand. |

## Recording flow

`_RecorderSheet` is opened with `isDismissible: false` + `enableDrag:
false` (you can't accidentally swipe away a live recording — use Cancel).
On open it immediately `_start()`s:

1. `AudioRecorder.hasPermission()` — false → show an error state with a
   Close button (no crash, no silent no-op).
2. `AudioStorageService.newRecordingPath()` → a fresh `<docs>/audio/<uuid>.m4a`.
3. `recorder.start(RecordConfig(encoder: AudioEncoder.aacLc), path:)`.
4. A 100 ms `Timer.periodic` drives the elapsed timer + progress bar and
   **auto-stops at `kMaxVoiceDuration`** so a forgotten recording can't
   grow without bound.

Stop pops a `VoiceRecording(path, durationMs: measuredElapsed)`. Cancel
stops the recorder, `deleteAtPath`s the half-written file, and pops null.

The measured duration comes from the **ticker elapsed**, not the file —
`audioplayers` re-reports the true duration via `onDurationChanged` on
first play, and `_VoicePlayer` upgrades `_total` when it does.

## Storage contract

Bytes are **never stored in Hive** — only the path string + `durationMs`.
Unlike the photo block, this widget does **not** copy bytes: the recorder
writes the `.m4a` directly to the path
[`AudioStorageService.newRecordingPath()`](../../../data/services/audio_storage_service.dart)
hands out. Re-record / Remove call `AudioStorageService.deleteAtPath` on
the previous path so old clips don't accumulate (best-effort — swallows
`FileSystemException`). `_record` deletes the old clip only **after** the
new one is captured, so a cancelled re-record keeps the original.

## Not an action block

`BlockTypeDisplay.isActionBlock` is **false** for voice (unlike photo /
memory). The filled cell hosts a sustained interactive player — the
play/pause `InkWell` must keep winning single taps — so it can't be a
one-shot "fire on engage" action. The outer `GestureDetector` uses
`HitTestBehavior.opaque` and only claims double-tap (expand); the inner
`InkWell` wins the single tap. Manage (Re-record / Remove) moved to the
top-right `BlockOptionsButton` so long-press is free for drag-to-reorder
(GUS-76). Recording is initiated by a tap on the **empty** cell instead.

## Permissions

- iOS [`Info.plist`](../../../../ios/Runner/Info.plist) —
  `NSMicrophoneUsageDescription`.
- Android [`AndroidManifest.xml`](../../../../android/app/src/main/AndroidManifest.xml) —
  `RECORD_AUDIO`.

`package:record` requests these at the OS level on first
`hasPermission()`.

## Gotchas

- **`AudioStorageService` is constructed in `main.dart` and exposed via
  `AppDependencies.audioStorage`.** The widget grabs it through
  `AppDependencies.of(context)`; don't instantiate one inside the widget.
- **Each `_VoicePlayer` is keyed by its audio path** (`ValueKey('voice-player-<path>')`)
  so a Re-record swaps in a fresh player + `AudioPlayer` rather than
  reusing the old one pointed at a now-deleted file.
- **`package:record` does not support Swift Package Manager** — the
  project keeps `enable-swift-package-manager: false` in `pubspec.yaml`,
  so the CocoaPods-based `record_darwin` plugin is used. `flutter
  analyze` prints a benign SPM warning about this; it is not an error.
- **Entry-delete doesn't cascade to audio files** — same caveat as the
  photo block. The sweep only removes entries with no content, and an
  audio-less voice block has no file to clean up.

## When to update this file

- Waveform / amplitude visualisation is added (the recorder exposes
  `onAmplitudeChanged`).
- The duration cap changes (`kMaxVoiceDuration`).
- Cascade-delete on entry removal is wired up — also document it in
  [data/repositories/CLAUDE.md](../../../data/repositories/CLAUDE.md).
