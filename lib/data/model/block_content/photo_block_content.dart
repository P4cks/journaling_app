class PhotoBlockContent {
  /// Absolute filesystem path to the stored image (under the app's
  /// documents directory, written by `PhotoStorageService`). Null when
  /// no photo has been picked yet.
  final String? photoPath;

  const PhotoBlockContent({this.photoPath});

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  factory PhotoBlockContent.fromMap(Map<String, dynamic> map) =>
      PhotoBlockContent(photoPath: map['photoPath'] as String?);

  Map<String, dynamic> toMap() => {
    if (photoPath != null) 'photoPath': photoPath,
  };
}
