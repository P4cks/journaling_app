/// Per-entry pin coordinates for a `BlockType.locationBlock`.
///
/// Stores a single latitude/longitude pair. The user drops the pin by
/// long-pressing on the map; a subsequent long-press moves it.
/// Coordinates are stored exactly as captured (no rounding) — the map
/// always recenters on the saved point when re-opened.
class LocationBlockContent {
  final double? latitude;
  final double? longitude;

  const LocationBlockContent({this.latitude, this.longitude});

  /// True when both coordinates are set — the pin is dropped.
  bool get hasPin => latitude != null && longitude != null;

  factory LocationBlockContent.fromMap(Map<String, dynamic> map) =>
      LocationBlockContent(
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
