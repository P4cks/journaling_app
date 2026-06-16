/// Typed wrapper over the voice block's content map.
///
/// Stores an absolute path to the recorded audio file (under
/// `<docs>/audio/<uuid>.m4a`, written by [AudioStorageService]) plus the
/// measured clip duration in milliseconds. Hive only persists the path +
/// duration; the audio bytes live on disk.
///
/// Map shape: `{"audioPath": "/.../audio/<uuid>.m4a", "durationMs": 4200}`
/// (each key omitted when null). `hasAudio` is true when a non-empty path
/// is stored.
class VoiceBlockContent {
  final String? audioPath;
  final int? durationMs;

  const VoiceBlockContent({this.audioPath, this.durationMs});

  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  factory VoiceBlockContent.fromMap(Map<String, dynamic> map) =>
      VoiceBlockContent(
        audioPath: map['audioPath'] as String?,
        durationMs: (map['durationMs'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
    if (audioPath != null) 'audioPath': audioPath,
    if (durationMs != null) 'durationMs': durationMs,
  };
}
