import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Copies picked video clips into the app's documents directory and
/// exposes the resulting filesystem paths for the video block. The block
/// content persists the absolute path string in the entry's
/// `contentJson` — keeping the bytes out of Hive avoids ballooning the
/// box file. Mirrors [PhotoStorageService].
class VideoStorageService {
  VideoStorageService();

  Directory? _videoDir;

  Future<Directory> _ensureVideoDir() async {
    final cached = _videoDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/video');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _videoDir = dir;
    return dir;
  }

  /// Copies [picked] into the app's `video/` directory under a fresh
  /// uuid filename. Returns the absolute path of the new file.
  Future<String> savePickedFile(XFile picked) async {
    final dir = await _ensureVideoDir();
    final ext = _extOf(picked.path);
    final dest = '${dir.path}/${_uuid.v4()}$ext';
    final bytes = await picked.readAsBytes();
    final file = File(dest);
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[VideoStorageService] saved $dest (${bytes.length} bytes)');
    return dest;
  }

  /// Deletes a file at [path] if it exists. Best-effort — swallows
  /// `FileSystemException`s so callers can use this in cleanup code
  /// without worrying about a missing file blowing up the flow.
  Future<void> deleteAtPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[VideoStorageService] deleted $path');
      }
    } on FileSystemException catch (error) {
      debugPrint('[VideoStorageService] delete failed: $error');
    }
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.mp4';
    final ext = path.substring(dot).toLowerCase();
    // Whitelist to safe video extensions; anything else falls back to mp4.
    const allowed = {'.mp4', '.mov', '.m4v'};
    return allowed.contains(ext) ? ext : '.mp4';
  }
}
