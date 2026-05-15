/// Stable string ids for the manual weather conditions.
///
/// Order is the carousel presentation order. The persisted value is the
/// id string itself, so reordering this list is safe — old entries keep
/// rendering whichever id they stored. Adding a new id is safe; removing
/// one means existing entries that stored it decode as `unknown` and
/// fall back to no selection.
const weatherConditionIds = <String>[
  'sun',
  'partly_cloudy',
  'cloud',
  'rain',
  'thunderstorm',
  'snow',
  'fog',
];

/// Default condition id seeded into newly-materialized manual weather
/// blocks. Must be present in [weatherConditionIds].
const defaultWeatherConditionId = 'cloud';

class WeatherBlockContent {
  final String? conditionId;

  const WeatherBlockContent({this.conditionId});

  factory WeatherBlockContent.fromMap(Map<String, dynamic> map) {
    final id = map['conditionId'] as String?;
    if (id == null || !weatherConditionIds.contains(id)) {
      return const WeatherBlockContent();
    }
    return WeatherBlockContent(conditionId: id);
  }

  Map<String, dynamic> toMap() => {
    if (conditionId != null) 'conditionId': conditionId,
  };
}
