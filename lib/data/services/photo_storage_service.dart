import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Copies picked images into the app's documents directory and exposes
/// the resulting filesystem paths for the photo block. The block
/// content persists the absolute path string in the entry's
/// `contentJson` — keeping the bytes out of Hive avoids ballooning the
/// box file.
class PhotoStorageService {
  PhotoStorageService();

  Directory? _photosDir;

  Future<Directory> _ensurePhotosDir() async {
    final cached = _photosDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _photosDir = dir;
    return dir;
  }

  /// Copies [picked] into the app's `photos/` directory under a fresh
  /// uuid filename. Returns the absolute path of the new file.
  Future<String> savePickedFile(XFile picked) async {
    final dir = await _ensurePhotosDir();
    final ext = _extOf(picked.path);
    final dest = '${dir.path}/${_uuid.v4()}$ext';
    final bytes = await picked.readAsBytes();
    final file = File(dest);
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[PhotoStorageService] saved $dest (${bytes.length} bytes)');
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
        debugPrint('[PhotoStorageService] deleted $path');
      }
    } on FileSystemException catch (error) {
      debugPrint('[PhotoStorageService] delete failed: $error');
    }
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    // Whitelist to safe image extensions; anything else falls back to jpg.
    const allowed = {'.jpg', '.jpeg', '.png', '.heic', '.webp', '.gif'};
    return allowed.contains(ext) ? ext : '.jpg';
  }
}
