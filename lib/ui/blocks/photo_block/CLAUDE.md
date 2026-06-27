# lib/ui/blocks/photo_block — Photo block widget

One `BlockType.photoBlock` block. Fills the 1×1 cell with a single
image. Content shape: `{"photoPath": "/.../photos/<uuid>.jpg"}`. Typed
wrapper: [PhotoBlockContent](../../../data/model/block_content/photo_block_content.dart).

## Files

- [photo_block_widget.dart](photo_block_widget.dart) — `PhotoBlockWidget`.
  Stateful — owns an [`ImagePicker`](https://pub.dev/packages/image_picker)
  instance + an in-flight pick flag.

## States and modes

| Mode + state | Render |
|---|---|
| `editable`, no photo | Centered image-glyph (`HugeIcons.strokeRoundedImage01`) + "Add photo" affordance; tap → Camera/Library action sheet. |
| `editable`, has photo | `Image.file` filling the cell (`BoxFit.cover`); top-right `⋯` [`BlockOptionsButton`](../widgets/block_options_button.dart) → Replace/Remove sheet; double-tap → expanded route. **Long-press is NOT handled** so it falls through to `BlockGrid`'s drag-to-reorder (GUS-76). |
| `readOnly`, no photo | Dimmed image-glyph (`HugeIcons.strokeRoundedImage01`) + "Photo" label, so the block is recognizable in previews like the layout editor (GUS-73) — was a bare italic "No photo". |
| `readOnly`, has photo | `Image.file` filling the cell. No interaction. |

## Storage contract

The widget never stores bytes in Hive — only the absolute path. Picked
files are copied into the app documents directory via
[`PhotoStorageService.savePickedFile`](../../../data/services/photo_storage_service.dart),
which writes to `<docs>/photos/<uuid>.<ext>`. Replacing or removing a
photo calls `PhotoStorageService.deleteAtPath` on the previous path so
old files don't accumulate (best-effort — swallows
`FileSystemException`).

The picker is configured with:

- `maxWidth: 2048`, `maxHeight: 2048`
- `imageQuality: 88`

…to keep on-device storage from blowing up while preserving enough
quality for casual journaling.

## Permissions

Required platform manifest entries (already present):

- iOS [`Info.plist`](../../../../ios/Runner/Info.plist) —
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.
- Android [`AndroidManifest.xml`](../../../../android/app/src/main/AndroidManifest.xml) —
  `CAMERA`, `READ_MEDIA_IMAGES`.

`image_picker` requests these at the OS level on first use.

## Gotchas

- **Missing file fallback**: `Image.file` is wrapped with an
  `errorBuilder` so a stale `photoPath` (e.g. user deleted the file
  through the OS) shows a dimmed "Image missing" placeholder instead
  of throwing.
- **Entry-delete doesn't currently cascade to photo files**. If you
  start deleting entries programmatically (beyond the sweep), wire
  `photoStorage.deleteAtPath` into `JournalRepository.deleteEntry` for
  every photo-block path in the deleted entry. Not done yet — the
  sweep only deletes entries that have no content, and a photo-less
  photo block has no file to clean up.
- **`PhotoStorageService` is constructed in `main.dart` and exposed
  through `AppDependencies.photoStorage`.** The widget grabs it via
  `AppDependencies.of(context)`; don't instantiate a new one inside
  the widget.

## When to update this file

- Multi-photo support is added.
- A camera-only or gallery-only variant is split out.
- Cascade-delete on entry removal is wired up — also document the
  invariant in [data/repositories/CLAUDE.md](../../../data/repositories/CLAUDE.md).
