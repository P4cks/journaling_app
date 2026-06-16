import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Owns the app's `audio/` directory for the voice block. Unlike
/// [PhotoStorageService], the recorder (`package:record`) writes the file
/// itself, so this service does not copy bytes — it just hands out a fresh
/// destination path via [newRecordingPath] and best-effort deletes on
/// cleanup. The block content persists the absolute path string in the
/// entry's `contentJson`, keeping the bytes out of Hive.
class AudioStorageService {
  AudioStorageService();

  Directory? _audioDir;

  Future<Directory> _ensureAudioDir() async {
    final cached = _audioDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _audioDir = dir;
    return dir;
  }

  /// Returns a fresh absolute path under the app's `audio/` directory for
  /// the recorder to write to. The `.m4a` extension matches the AAC-LC
  /// encoder the recorder uses.
  Future<String> newRecordingPath() async {
    final dir = await _ensureAudioDir();
    final dest = '${dir.path}/${_uuid.v4()}.m4a';
    debugPrint('[AudioStorageService] new recording path $dest');
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
        debugPrint('[AudioStorageService] deleted $path');
      }
    } on FileSystemException catch (error) {
      debugPrint('[AudioStorageService] delete failed: $error');
    }
  }
}
