import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

/// Value object for one ZenQuotes payload.
class DailyQuote {
  final String quote;
  final String author;
  final String fetchedDate; // yyyy-MM-dd

  const DailyQuote({
    required this.quote,
    required this.author,
    required this.fetchedDate,
  });

  Map<String, dynamic> toMap() => {
    'quote': quote,
    'author': author,
    'fetchedDate': fetchedDate,
  };

  factory DailyQuote.fromMap(Map<String, dynamic> map) => DailyQuote(
    quote: (map['quote'] as String?) ?? '',
    author: (map['author'] as String?) ?? '',
    fetchedDate: (map['fetchedDate'] as String?) ?? '',
  );
}

/// Fetches the daily quote from ZenQuotes' `/api/today` endpoint and
/// caches the result in the `settings` Hive box under `quote.<date>`.
/// All entries created on the same calendar day share the same quote.
///
/// Failures bubble up as `null` from [getTodayQuote]; the widget is
/// expected to render a graceful fallback and offer retry.
class QuoteService {
  QuoteService(Box<String> settingsBox, {http.Client? httpClient})
      : _box = settingsBox,
        _http = httpClient ?? http.Client();

  static const _endpoint = 'https://zenquotes.io/api/today';
  static const _keyPrefix = 'quote.';

  final Box<String> _box;
  final http.Client _http;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DailyQuote? readCached(DateTime date) {
    final raw = _box.get('$_keyPrefix${_formatDate(date)}');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return DailyQuote.fromMap(decoded);
    } catch (_) {}
    return null;
  }

  /// Returns today's quote, fetching from ZenQuotes on cache miss.
  /// Returns `null` on network/parse failure. Pass [now] in tests.
  Future<DailyQuote?> getTodayQuote({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final cached = readCached(today);
    if (cached != null) {
      debugPrint('[QuoteService] cache hit for ${_formatDate(today)}');
      return cached;
    }
    try {
      final res = await _http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint('[QuoteService] HTTP ${res.statusCode}');
        return null;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map) return null;
      final quote = (first['q'] as String?)?.trim();
      final author = (first['a'] as String?)?.trim();
      if (quote == null || quote.isEmpty) return null;
      final daily = DailyQuote(
        quote: quote,
        author: author ?? '',
        fetchedDate: _formatDate(today),
      );
      await _box.put(
        '$_keyPrefix${_formatDate(today)}',
        jsonEncode(daily.toMap()),
      );
      debugPrint('[QuoteService] fetched + cached for ${_formatDate(today)}');
      return daily;
    } catch (error) {
      debugPrint('[QuoteService] fetch failed: $error');
      return null;
    }
  }
}
