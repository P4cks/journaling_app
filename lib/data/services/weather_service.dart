import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

/// Outcome of a weather fetch attempt.
enum WeatherFetchStatus {
  ok,
  permissionDenied,
  locationDisabled,
  networkFailure,
}

class WeatherFetchResult {
  final WeatherFetchStatus status;
  final String? conditionId;
  final double? temperatureC;
  final String? cityName; // best-effort, may be null if reverse-geocode fails
  final String? fetchedDate; // yyyy-MM-dd

  const WeatherFetchResult({
    required this.status,
    this.conditionId,
    this.temperatureC,
    this.cityName,
    this.fetchedDate,
  });

  bool get isOk => status == WeatherFetchStatus.ok;
}

/// Fetches current weather from [Open-Meteo](https://open-meteo.com)
/// (no API key required) for the device's location, then maps the
/// numeric `weathercode` onto the same condition-id strings used by
/// the manual weather block. Caches per `(date, rounded-location)` in
/// the `settings` Hive box so the second open of the same day skips
/// both the GPS and the HTTP round-trip.
class WeatherService {
  WeatherService(
    Box<String> settingsBox, {
    http.Client? httpClient,
    Future<bool> Function()? checkServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? getCurrentPosition,
  }) : _box = settingsBox,
       _http = httpClient ?? http.Client(),
       _checkServiceEnabled =
           checkServiceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _requestPermission = requestPermission ?? Geolocator.requestPermission,
       _getCurrentPosition =
           getCurrentPosition ??
           (() => Geolocator.getCurrentPosition(
             locationSettings: const LocationSettings(
               accuracy: LocationAccuracy.low,
             ),
           ));

  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';
  static const _nominatimEndpoint =
      'https://nominatim.openstreetmap.org/reverse';
  // Identifies the app per the Nominatim usage policy.
  static const _nominatimUserAgent =
      'journaling_app_rewrite/1.0 (https://github.com/P4cks/journaling_app)';
  static const _keyPrefix = 'weather.';

  final Box<String> _box;
  final http.Client _http;
  final Future<bool> Function() _checkServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Round to ~10km so repeated fetches around a city all share a cache
  /// entry. Open-Meteo's grid resolution is much coarser than this so
  /// we don't lose accuracy in practice.
  String _locationBucket(double lat, double lon) {
    return '${lat.toStringAsFixed(1)}_${lon.toStringAsFixed(1)}';
  }

  String _cacheKey(DateTime date, double lat, double lon) =>
      '$_keyPrefix${_formatDate(date)}.${_locationBucket(lat, lon)}';

  WeatherFetchResult? _readCachedForDate(DateTime date) {
    final prefix = '$_keyPrefix${_formatDate(date)}.';
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        return WeatherFetchResult(
          status: WeatherFetchStatus.ok,
          conditionId: decoded['conditionId'] as String?,
          temperatureC: (decoded['temperatureC'] as num?)?.toDouble(),
          cityName: decoded['cityName'] as String?,
          fetchedDate: decoded['fetchedDate'] as String?,
        );
      } catch (_) {}
    }
    return null;
  }

  /// Best-effort reverse-geocode via OSM Nominatim. Returns null on any
  /// failure (rate limit, network, parse error) — callers should treat
  /// it as "city unknown" and render without it.
  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(_nominatimEndpoint).replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'zoom': '10',
        },
      );
      final res = await _http
          .get(uri, headers: {'User-Agent': _nominatimUserAgent})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final address = decoded['address'];
      if (address is! Map) return null;
      // Nominatim returns one of city/town/village depending on the
      // place size. Prefer the most specific, fall back to less so.
      final locality = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['hamlet'] ??
              address['municipality'] ??
              address['county']) as String?;
      final country = address['country'] as String?;
      if (locality == null && country == null) return null;
      if (locality != null && country != null) return '$locality, $country';
      return locality ?? country;
    } catch (error) {
      debugPrint('[WeatherService] reverse-geocode failed: $error');
      return null;
    }
  }

  /// Maps Open-Meteo's [WMO weather codes](https://open-meteo.com/en/docs)
  /// onto the seven condition ids used by `WeatherBlockContent`.
  static String mapWeatherCode(int code) {
    switch (code) {
      case 0:
        return 'sun';
      case 1:
      case 2:
        return 'partly_cloudy';
      case 3:
        return 'cloud';
      case 45:
      case 48:
        return 'fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'snow';
      case 95:
      case 96:
      case 99:
        return 'thunderstorm';
      default:
        return 'cloud';
    }
  }

  /// Fetches current weather for the device's location, falling back to
  /// the cached value for the given date if available. Honors location
  /// permissions and reports degraded states via [WeatherFetchStatus].
  Future<WeatherFetchResult> getCurrentWeather({DateTime? now}) async {
    final today = now ?? DateTime.now();

    // Permission gate
    final serviceEnabled = await _checkServiceEnabled();
    if (!serviceEnabled) {
      final cached = _readCachedForDate(today);
      if (cached != null) return cached;
      return const WeatherFetchResult(
        status: WeatherFetchStatus.locationDisabled,
      );
    }

    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final cached = _readCachedForDate(today);
      if (cached != null) return cached;
      return const WeatherFetchResult(
        status: WeatherFetchStatus.permissionDenied,
      );
    }

    try {
      final position = await _getCurrentPosition();
      final cacheKey = _cacheKey(today, position.latitude, position.longitude);
      final cachedRaw = _box.get(cacheKey);
      if (cachedRaw != null) {
        try {
          final decoded = jsonDecode(cachedRaw);
          if (decoded is Map) {
            debugPrint('[WeatherService] cache hit $cacheKey');
            var cachedCity = decoded['cityName'] as String?;
            // Backfill cityName for entries cached before reverse-
            // geocoding existed. The reverse-geocode call is
            // best-effort; if it fails we just return without a city
            // and try again next time.
            if (cachedCity == null) {
              cachedCity = await _reverseGeocode(
                position.latitude,
                position.longitude,
              );
              if (cachedCity != null) {
                final updated = Map<String, dynamic>.from(decoded);
                updated['cityName'] = cachedCity;
                await _box.put(cacheKey, jsonEncode(updated));
                debugPrint(
                  '[WeatherService] backfilled cityName for $cacheKey '
                  '($cachedCity)',
                );
              }
            }
            return WeatherFetchResult(
              status: WeatherFetchStatus.ok,
              conditionId: decoded['conditionId'] as String?,
              temperatureC: (decoded['temperatureC'] as num?)?.toDouble(),
              cityName: cachedCity,
              fetchedDate: decoded['fetchedDate'] as String?,
            );
          }
        } catch (_) {}
      }

      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'current_weather': 'true',
        },
      );
      final res = await _http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint('[WeatherService] HTTP ${res.statusCode}');
        return const WeatherFetchResult(
          status: WeatherFetchStatus.networkFailure,
        );
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const WeatherFetchResult(
          status: WeatherFetchStatus.networkFailure,
        );
      }
      final current = decoded['current_weather'];
      if (current is! Map) {
        return const WeatherFetchResult(
          status: WeatherFetchStatus.networkFailure,
        );
      }
      final code = (current['weathercode'] as num?)?.toInt();
      final temp = (current['temperature'] as num?)?.toDouble();
      if (code == null) {
        return const WeatherFetchResult(
          status: WeatherFetchStatus.networkFailure,
        );
      }
      final conditionId = mapWeatherCode(code);
      final fetchedDate = _formatDate(today);
      // Reverse-geocode is best-effort. Don't fail the whole fetch if
      // Nominatim is rate-limiting or unreachable.
      final cityName = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      final payload = <String, dynamic>{
        'conditionId': conditionId,
        'temperatureC': ?temp,
        'cityName': ?cityName,
        'fetchedDate': fetchedDate,
      };
      await _box.put(cacheKey, jsonEncode(payload));
      debugPrint(
        '[WeatherService] fetched + cached $cacheKey '
        '($conditionId, $temp°C, $cityName)',
      );
      return WeatherFetchResult(
        status: WeatherFetchStatus.ok,
        conditionId: conditionId,
        temperatureC: temp,
        cityName: cityName,
        fetchedDate: fetchedDate,
      );
    } catch (error) {
      debugPrint('[WeatherService] fetch failed: $error');
      final cached = _readCachedForDate(today);
      if (cached != null) return cached;
      return const WeatherFetchResult(
        status: WeatherFetchStatus.networkFailure,
      );
    }
  }
}
