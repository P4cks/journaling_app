/// Per-entry snapshot of an API-fetched weather observation.
///
/// Mirrors [WeatherBlockContent]'s `conditionId` field so the same
/// icon-mapping helper can render both manual and API blocks. The
/// `temperatureC` field is API-only.
class WeatherApiBlockContent {
  final String? conditionId;
  final double? temperatureC;
  final String? fetchedDate; // yyyy-MM-dd this snapshot was locked in
  final String? error; // optional surfaced failure ("permission_denied", etc.)

  const WeatherApiBlockContent({
    this.conditionId,
    this.temperatureC,
    this.fetchedDate,
    this.error,
  });

  bool get isFetched => conditionId != null && conditionId!.isNotEmpty;

  factory WeatherApiBlockContent.fromMap(Map<String, dynamic> map) =>
      WeatherApiBlockContent(
        conditionId: map['conditionId'] as String?,
        temperatureC: (map['temperatureC'] as num?)?.toDouble(),
        fetchedDate: map['fetchedDate'] as String?,
        error: map['error'] as String?,
      );

  Map<String, dynamic> toMap() => {
    if (conditionId != null) 'conditionId': conditionId,
    if (temperatureC != null) 'temperatureC': temperatureC,
    if (fetchedDate != null) 'fetchedDate': fetchedDate,
    if (error != null) 'error': error,
  };
}
