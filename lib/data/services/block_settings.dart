import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

/// How a prompt is chosen when materializing a prompt block.
///
/// - [daily] — deterministic from the entry's date AND the slot's index
///   among prompt-block slots in the layout. Same date + same slot →
///   same prompt. Different slots on the same date → different prompts
///   (when the list is at least as long as the slot count). Each
///   prompt rotates through every slot evenly over time.
/// - [manual] — no prompt is picked at materialization. The widget
///   prompts the user to choose one via a bottom sheet on first open
///   of the entry. Long-pressing the block opens the picker again
///   (regardless of strategy — long-press is a manual override).
///
/// Legacy `random` values stored on existing users' devices read back
/// as [daily] (the toggle's default OFF position).
enum PromptStrategy { daily, manual }

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

  // Day 0 for the daily deterministic pick. The exact date is
  // unimportant — only the relative day count matters.
  static final DateTime _dailyEpoch = DateTime(2024, 1, 1);

  List<String> _prompts = const [];
  PromptStrategy _promptStrategy = PromptStrategy.daily;
  String? _moodTitle;
  String? _weatherTitle;
  List<CustomCarouselDefinition> _customCarousels = const [];

  List<String> get prompts => List.unmodifiable(_prompts);
  PromptStrategy get promptStrategy => _promptStrategy;
  String? get moodTitle => _moodTitle;
  String? get weatherTitle => _weatherTitle;
  List<CustomCarouselDefinition> get customCarousels =>
      List.unmodifiable(_customCarousels);

  CustomCarouselDefinition? findCustomCarousel(String id) {
    for (final def in _customCarousels) {
      if (def.id == id) return def;
    }
    return null;
  }

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
    // Legacy 'random' values fall through to daily — the toggle no
    // longer surfaces a random option.
    if (strategy == PromptStrategy.manual.name) {
      _promptStrategy = PromptStrategy.manual;
    } else {
      _promptStrategy = PromptStrategy.daily;
    }
    final moodTitleRaw = _storage.getBlockMoodTitle();
    if (moodTitleRaw != null && moodTitleRaw.trim().isNotEmpty) {
      _moodTitle = moodTitleRaw;
    }
    final weatherTitleRaw = _storage.getBlockWeatherTitle();
    if (weatherTitleRaw != null && weatherTitleRaw.trim().isNotEmpty) {
      _weatherTitle = weatherTitleRaw;
    }
    final customCarouselsRaw =
        _storage.getBlockCustomCarouselDefinitionsJson();
    if (customCarouselsRaw != null && customCarouselsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(customCarouselsRaw);
        if (decoded is List) {
          _customCarousels = [
            for (final raw in decoded)
              if (raw is Map<String, dynamic>)
                CustomCarouselDefinition.fromMap(raw),
          ];
        }
      } catch (_) {
        // Corrupt JSON — fall back to empty.
      }
    }
  }

  Future<void> _persistCustomCarousels() async {
    final json = _customCarousels.isEmpty
        ? null
        : jsonEncode([for (final def in _customCarousels) def.toMap()]);
    await _storage.setBlockCustomCarouselDefinitionsJson(json);
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

  Future<void> setMoodTitle(String? title) async {
    final normalized = (title == null || title.trim().isEmpty)
        ? null
        : title.trim();
    if (_moodTitle == normalized) return;
    _moodTitle = normalized;
    await _storage.setBlockMoodTitle(normalized);
    debugPrint('[BlockSettings] setMoodTitle -> $normalized');
    notifyListeners();
  }

  Future<void> setWeatherTitle(String? title) async {
    final normalized = (title == null || title.trim().isEmpty)
        ? null
        : title.trim();
    if (_weatherTitle == normalized) return;
    _weatherTitle = normalized;
    await _storage.setBlockWeatherTitle(normalized);
    debugPrint('[BlockSettings] setWeatherTitle -> $normalized');
    notifyListeners();
  }

  /// Append a new custom carousel definition to the registry. The caller
  /// is responsible for the id (uuid) and for title uniqueness checks —
  /// `BlockSettings` just persists and notifies.
  Future<void> addCustomCarousel(CustomCarouselDefinition definition) async {
    _customCarousels = [..._customCarousels, definition];
    await _persistCustomCarousels();
    debugPrint(
      '[BlockSettings] addCustomCarousel id=${definition.id} title="${definition.title}"',
    );
    notifyListeners();
  }

  /// Replace a custom carousel by id. No-op when id is not found.
  Future<void> updateCustomCarousel(CustomCarouselDefinition definition) async {
    final next = [..._customCarousels];
    final i = next.indexWhere((d) => d.id == definition.id);
    if (i < 0) return;
    next[i] = definition;
    _customCarousels = next;
    await _persistCustomCarousels();
    debugPrint(
      '[BlockSettings] updateCustomCarousel id=${definition.id} title="${definition.title}"',
    );
    notifyListeners();
  }

  /// Remove a custom carousel by id. Existing layouts / entries that
  /// reference it are left untouched — the widget renders a deleted
  /// placeholder when the lookup fails.
  Future<void> deleteCustomCarousel(String id) async {
    final next = [..._customCarousels]..removeWhere((d) => d.id == id);
    if (next.length == _customCarousels.length) return;
    _customCarousels = next;
    await _persistCustomCarousels();
    debugPrint('[BlockSettings] deleteCustomCarousel id=$id');
    notifyListeners();
  }

  /// Pick a prompt for a single prompt-block slot.
  ///
  /// Returns `null` when:
  /// - no prompts are configured, OR
  /// - the strategy is [PromptStrategy.manual] (the widget will open
  ///   the picker on first build).
  ///
  /// The caller is expected to render an empty placeholder for `null`.
  String? pickPromptFor({required DateTime date, required int slotIndex}) {
    if (_promptStrategy == PromptStrategy.manual) return null;
    if (_prompts.isEmpty) return null;
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
