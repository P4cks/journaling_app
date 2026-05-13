import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

/// How a prompt is chosen when materializing a prompt block.
///
/// - [daily] — deterministic from the entry's date AND the slot's index
///   among prompt-block slots in the layout. Same date + same slot →
///   same prompt. Different slots on the same date → different prompts
///   (when the list is at least as long as the slot count). Each
///   prompt rotates through every slot evenly over time.
/// - [random] — independent random pick per prompt block at
///   materialization time.
enum PromptStrategy { daily, random }

/// Block-type-global settings, persisted in the `settings` Hive box.
///
/// One instance is constructed in `main.dart` and exposed via
/// `AppDependencies`. Listeners (Profile settings screens, text block
/// widget, prompt picker) react to changes via `ChangeNotifier`.
///
/// **Prompt picking semantics.** When `JournalRepository.materializeLayout`
/// creates a new entry, it asks this object for each prompt block slot's
/// initial prompt via [pickPromptFor]. The prompt is then baked into
/// the entry's content map and persists for the lifetime of that entry
/// — re-opening the entry does not re-roll. Editing the prompt list
/// afterwards only affects entries created after the edit.
class BlockSettings extends ChangeNotifier {
  BlockSettings(this._storage) {
    _load();
  }

  final SettingsStorageService _storage;
  final Random _rng = Random();

  // Day 0 for the daily deterministic pick. The exact date is
  // unimportant — only the relative day count matters.
  static final DateTime _dailyEpoch = DateTime(2024, 1, 1);

  List<String> _prompts = const [];
  PromptStrategy _promptStrategy = PromptStrategy.daily;
  int? _textCharLimit;

  List<String> get prompts => List.unmodifiable(_prompts);
  PromptStrategy get promptStrategy => _promptStrategy;
  int? get textCharLimit => _textCharLimit;

  void _load() {
    final raw = _storage.getBlockPromptListJson();
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _prompts = [
            for (final v in decoded)
              if (v is String && v.trim().isNotEmpty) v.trim(),
          ];
        }
      } catch (_) {
        // Corrupt JSON — fall back to empty.
      }
    }
    final strategy = _storage.getBlockPromptStrategy();
    if (strategy == PromptStrategy.random.name) {
      _promptStrategy = PromptStrategy.random;
    } else {
      _promptStrategy = PromptStrategy.daily;
    }
    final limitRaw = _storage.getBlockTextCharLimit();
    if (limitRaw != null) {
      final parsed = int.tryParse(limitRaw);
      if (parsed != null && parsed > 0) _textCharLimit = parsed;
    }
  }

  Future<void> setPrompts(List<String> prompts) async {
    final cleaned = [
      for (final p in prompts)
        if (p.trim().isNotEmpty) p.trim(),
    ];
    if (listEquals(cleaned, _prompts)) return;
    _prompts = List.unmodifiable(cleaned);
    await _storage.setBlockPromptListJson(
      cleaned.isEmpty ? null : jsonEncode(cleaned),
    );
    debugPrint('[BlockSettings] setPrompts -> ${cleaned.length} prompts');
    notifyListeners();
  }

  Future<void> setPromptStrategy(PromptStrategy strategy) async {
    if (_promptStrategy == strategy) return;
    _promptStrategy = strategy;
    await _storage.setBlockPromptStrategy(strategy.name);
    debugPrint('[BlockSettings] setPromptStrategy -> ${strategy.name}');
    notifyListeners();
  }

  Future<void> setTextCharLimit(int? limit) async {
    final normalized = (limit != null && limit > 0) ? limit : null;
    if (_textCharLimit == normalized) return;
    _textCharLimit = normalized;
    await _storage.setBlockTextCharLimit(normalized);
    debugPrint('[BlockSettings] setTextCharLimit -> $normalized');
    notifyListeners();
  }

  /// Pick a prompt for a single prompt-block slot.
  ///
  /// Returns `null` when no prompts are configured — the caller is
  /// expected to render an empty placeholder.
  String? pickPromptFor({required DateTime date, required int slotIndex}) {
    if (_prompts.isEmpty) return null;
    if (_promptStrategy == PromptStrategy.random) {
      return _prompts[_rng.nextInt(_prompts.length)];
    }
    final day = DateTime(date.year, date.month, date.day);
    final ordinal = day.difference(_dailyEpoch).inDays;
    final n = _prompts.length;
    final raw = (ordinal + slotIndex) % n;
    // Dart's % returns a value of the same sign as the dividend for
    // negative `ordinal` (e.g. a date before _dailyEpoch). Normalise to
    // a non-negative index.
    final idx = (raw + n) % n;
    return _prompts[idx];
  }
}
