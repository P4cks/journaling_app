import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

/// How a prompt is chosen when materializing a prompt block.
///
/// - [random] — deterministic from the entry's date AND the slot's index
///   among prompt-block slots in the layout. Same date + same slot →
///   same prompt. Different slots on the same date → different prompts
///   (when the list is at least as long as the slot count). Each
///   prompt rotates through every slot evenly over time.
/// - [manual] — no prompt is picked at materialization. The widget
///   prompts the user to choose one via a bottom sheet on first open
///   of the entry. Long-pressing the block opens the picker again
///   (regardless of strategy — long-press is a manual override).
///
/// Legacy `daily` values stored on existing users' devices read back
/// as [random] (the toggle's default ON position).
enum PromptStrategy { random, manual }

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
  PromptStrategy _promptStrategy = PromptStrategy.random;
  bool _carouselTitlesEnabled = true;
  List<CustomCarouselDefinition> _customCarousels = const [];

  /// Block types that the memory block is allowed to snapshot from.
  /// Defaults to the historical hardcoded set — text, mood, and
  /// photo blocks. The user can narrow or widen this via the
  /// Block-settings → Memory section. Memory blocks themselves are
  /// excluded by design (memory-of-a-memory is recursive). Prompt
  /// blocks are off by default (they're shaped differently and feel
  /// weird as memories) but can be enabled.
  static const Set<BlockType> defaultMemoryEligibleTypes = <BlockType>{
    BlockType.textBlock,
    BlockType.moodTracker,
    BlockType.photoBlock,
  };
  Set<BlockType> _memoryEligibleTypes = defaultMemoryEligibleTypes;

  List<String> get prompts => List.unmodifiable(_prompts);
  PromptStrategy get promptStrategy => _promptStrategy;

  /// Whether titles render above every carousel block (mood, manual
  /// weather, custom carousels). When `false`, all three carousel
  /// widgets pass `null` to [BlockWithTitle] so the row collapses
  /// entirely. Defaults to `true` on first launch.
  bool get carouselTitlesEnabled => _carouselTitlesEnabled;

  List<CustomCarouselDefinition> get customCarousels =>
      List.unmodifiable(_customCarousels);

  /// Eligible block types for memory snapshots. Returned as an
  /// unmodifiable set; mutate via [setMemoryEligibleTypes]. Memory
  /// blocks themselves are filtered out before the set hits storage
  /// (memory-of-a-memory recursion is never useful), so the UI may
  /// surface `BlockType.memoryBlock` but the value here will never
  /// contain it.
  Set<BlockType> get memoryEligibleTypes =>
      Set.unmodifiable(_memoryEligibleTypes);

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
    // Any non-'manual' value (including legacy 'daily') falls through
    // to the auto-rotation strategy.
    if (strategy == PromptStrategy.manual.name) {
      _promptStrategy = PromptStrategy.manual;
    } else {
      _promptStrategy = PromptStrategy.random;
    }
    final titlesEnabledRaw = _storage.getBlockCarouselTitlesEnabled();
    if (titlesEnabledRaw != null) {
      _carouselTitlesEnabled = titlesEnabledRaw;
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
    final memoryRaw = _storage.getBlockMemoryEligibleTypesJson();
    if (memoryRaw != null && memoryRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(memoryRaw);
        if (decoded is List) {
          final byName = {for (final t in BlockType.values) t.name: t};
          _memoryEligibleTypes = {
            for (final v in decoded)
              if (v is String && byName.containsKey(v) && v != BlockType.memoryBlock.name)
                byName[v]!,
          };
        }
      } catch (_) {
        // Corrupt JSON — fall back to the default.
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

  Future<void> setCarouselTitlesEnabled(bool value) async {
    if (_carouselTitlesEnabled == value) return;
    _carouselTitlesEnabled = value;
    await _storage.setBlockCarouselTitlesEnabled(value);
    debugPrint('[BlockSettings] setCarouselTitlesEnabled -> $value');
    notifyListeners();
  }

  /// Replace the memory-block eligible-types set. The memoryBlock
  /// type itself is filtered out before persistence (memory-of-a-
  /// memory recursion). Passing the default set persists `null` so
  /// future default changes propagate to all users.
  Future<void> setMemoryEligibleTypes(Set<BlockType> types) async {
    final cleaned = types.where((t) => t != BlockType.memoryBlock).toSet();
    if (setEquals(cleaned, _memoryEligibleTypes)) return;
    _memoryEligibleTypes = cleaned;
    final isDefault = setEquals(cleaned, defaultMemoryEligibleTypes);
    await _storage.setBlockMemoryEligibleTypesJson(
      isDefault ? null : jsonEncode([for (final t in cleaned) t.name]),
    );
    debugPrint(
      '[BlockSettings] setMemoryEligibleTypes -> ${cleaned.length} types',
    );
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
