class VideoBlockContent {
  /// Absolute filesystem path to the stored clip (under the app's
  /// documents directory, written by `VideoStorageService`). Null when
  /// no video has been captured yet.
  final String? videoPath;

  /// Clip length in milliseconds, captured at save time so the cell can
  /// show a duration badge without initialising a player. Null when
  /// unknown.
  final int? durationMs;

  const VideoBlockContent({this.videoPath, this.durationMs});

  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;

  factory VideoBlockContent.fromMap(Map<String, dynamic> map) =>
      VideoBlockContent(
        videoPath: map['videoPath'] as String?,
        durationMs: (map['durationMs'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
    if (videoPath != null) 'videoPath': videoPath,
    if (durationMs != null) 'durationMs': durationMs,
  };
}
