import 'package:hive_ce/hive.dart';

class SettingsStorageService {
  static const _defaultLayoutIdKey = 'defaultLayoutId';
  static const _debugMenuVisibleKey = 'debug.menuVisible';
  static const _unlockAllDaysKey = 'debug.unlockAllDays';
  static const _themeModeKey = 'theme.mode';
  static const _themePaletteIdKey = 'theme.paletteId';
  static const _themeSecondaryKey = 'theme.secondary';
  static const _themeAccentKey = 'theme.accent';
  static const _themeCustomPalettesKey = 'theme.customPalettes';
  static const _themeDebugSurfaceKey = 'theme.debugSurface';
  static const _blockPromptListKey = 'block.prompt.list';
  static const _blockPromptStrategyKey = 'block.prompt.strategy';
  static const _blockCarouselTitlesEnabledKey = 'block.carousel.titlesEnabled';
  static const _blockCustomCarouselDefinitionsKey =
      'block.customCarousel.definitions';
  static const _blockHabitDefinitionsKey = 'block.habit.definitions';
  static const _blockWannadosKey = 'block.wannado.items';
  static const _themePostItModeKey = 'theme.postItMode';
  static const _themePostItPaletteKey = 'theme.postItPalette';
  static const _debugExpandedDoneButtonKey =
      'debug.expandedBlock.showDoneButton';
  static const _blockMemoryEligibleTypesKey = 'block.memory.eligibleTypes';
  static const _subscriptionLastKnownProKey = 'subscription.lastKnownPro';
  static const _subscriptionDebugForceFreeKey = 'subscription.debugForceFree';
  // Debug-only per-block input-limit overrides. Absent → use the
  // hard-coded default in BlockInputLimits. Stored as the int's string
  // form; deleted when cleared back to default.
  static const _limitTextBlockKey = 'debug.limit.textBlock';
  static const _limitTextSectionKey = 'debug.limit.textSection';
  static const _limitPromptKey = 'debug.limit.prompt';
  static const _limitTodoItemKey = 'debug.limit.todoItem';
  static const _limitTodoMaxItemsKey = 'debug.limit.todoMaxItems';
  // Legacy key `block.expandOnEdit` is intentionally not read anymore
  // — both single-tap (in-place edit) and double-tap (expanded route)
  // are always active. Old values on disk are harmless under the
  // pre-1.0 settings-box backwards-compat policy.

  final Box<String> _box;

  SettingsStorageService(this._box);

  String? getDefaultLayoutId() => _box.get(_defaultLayoutIdKey);

  Future<void> setDefaultLayoutId(String id) =>
      _box.put(_defaultLayoutIdKey, id);

  Future<void> clearDefaultLayoutId() => _box.delete(_defaultLayoutIdKey);

  bool getUnlockAllDays() => _box.get(_unlockAllDaysKey) == 'true';

  Future<void> setUnlockAllDays(bool value) =>
      _box.put(_unlockAllDaysKey, value.toString());

  bool getDebugMenuVisible() => _box.get(_debugMenuVisibleKey) == 'true';

  Future<void> setDebugMenuVisible(bool value) =>
      _box.put(_debugMenuVisibleKey, value.toString());

  String? getThemeMode() => _box.get(_themeModeKey);

  Future<void> setThemeMode(String value) => _box.put(_themeModeKey, value);

  String? getThemePaletteId() => _box.get(_themePaletteIdKey);

  Future<void> setThemePaletteId(String value) =>
      _box.put(_themePaletteIdKey, value);

  String? getThemeSecondary() => _box.get(_themeSecondaryKey);

  Future<void> setThemeSecondary(String? hex) => hex == null
      ? _box.delete(_themeSecondaryKey)
      : _box.put(_themeSecondaryKey, hex);

  String? getThemeAccent() => _box.get(_themeAccentKey);

  Future<void> setThemeAccent(String? hex) => hex == null
      ? _box.delete(_themeAccentKey)
      : _box.put(_themeAccentKey, hex);

  String? getThemeCustomPalettes() => _box.get(_themeCustomPalettesKey);

  Future<void> setThemeCustomPalettes(String json) =>
      _box.put(_themeCustomPalettesKey, json);

  String? getThemeDebugSurface() => _box.get(_themeDebugSurfaceKey);

  Future<void> setThemeDebugSurface(String? hex) => hex == null
      ? _box.delete(_themeDebugSurfaceKey)
      : _box.put(_themeDebugSurfaceKey, hex);

  String? getBlockPromptListJson() => _box.get(_blockPromptListKey);

  Future<void> setBlockPromptListJson(String? json) => json == null
      ? _box.delete(_blockPromptListKey)
      : _box.put(_blockPromptListKey, json);

  String? getBlockPromptStrategy() => _box.get(_blockPromptStrategyKey);

  Future<void> setBlockPromptStrategy(String value) =>
      _box.put(_blockPromptStrategyKey, value);

  // null = key absent (use the default, currently `true`).
  bool? getBlockCarouselTitlesEnabled() {
    final raw = _box.get(_blockCarouselTitlesEnabledKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> setBlockCarouselTitlesEnabled(bool value) =>
      _box.put(_blockCarouselTitlesEnabledKey, value.toString());

  String? getBlockCustomCarouselDefinitionsJson() =>
      _box.get(_blockCustomCarouselDefinitionsKey);

  Future<void> setBlockCustomCarouselDefinitionsJson(String? json) =>
      (json == null || json.isEmpty)
      ? _box.delete(_blockCustomCarouselDefinitionsKey)
      : _box.put(_blockCustomCarouselDefinitionsKey, json);

  String? getBlockHabitDefinitionsJson() => _box.get(_blockHabitDefinitionsKey);

  Future<void> setBlockHabitDefinitionsJson(String? json) =>
      (json == null || json.isEmpty)
      ? _box.delete(_blockHabitDefinitionsKey)
      : _box.put(_blockHabitDefinitionsKey, json);

  String? getBlockWannadosJson() => _box.get(_blockWannadosKey);

  Future<void> setBlockWannadosJson(String? json) =>
      (json == null || json.isEmpty)
      ? _box.delete(_blockWannadosKey)
      : _box.put(_blockWannadosKey, json);

  // null = key absent (use the default, currently `true`).
  bool? getThemePostItMode() {
    final raw = _box.get(_themePostItModeKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> setThemePostItMode(bool value) =>
      _box.put(_themePostItModeKey, value.toString());

  String? getThemePostItPalette() => _box.get(_themePostItPaletteKey);

  Future<void> setThemePostItPalette(String? json) =>
      (json == null || json.isEmpty)
      ? _box.delete(_themePostItPaletteKey)
      : _box.put(_themePostItPaletteKey, json);

  bool getDebugExpandedDoneButton() =>
      _box.get(_debugExpandedDoneButtonKey) == 'true';

  Future<void> setDebugExpandedDoneButton(bool value) =>
      _box.put(_debugExpandedDoneButtonKey, value.toString());

  /// JSON-encoded list of `BlockType.name` strings that memory blocks
  /// are allowed to snapshot from. `null` = absent → caller uses the
  /// built-in default. `[]` = user explicitly cleared the list (memory
  /// blocks won't pick anything).
  String? getBlockMemoryEligibleTypesJson() =>
      _box.get(_blockMemoryEligibleTypesKey);

  Future<void> setBlockMemoryEligibleTypesJson(String? json) =>
      (json == null || json.isEmpty)
      ? _box.delete(_blockMemoryEligibleTypesKey)
      : _box.put(_blockMemoryEligibleTypesKey, json);

  /// Last-known Pro entitlement state, persisted so a cold start while
  /// offline (where the RevenueCat cache may be unavailable) can still
  /// honour an existing subscription. Absent → never seen Pro → `false`.
  bool getSubscriptionLastKnownPro() =>
      _box.get(_subscriptionLastKnownProKey) == 'true';

  Future<void> setSubscriptionLastKnownPro(bool value) =>
      _box.put(_subscriptionLastKnownProKey, value.toString());

  /// Debug-only override that makes the app behave as a free account
  /// regardless of the real entitlement (lets developers test the free
  /// experience). Absent → `false`.
  bool getSubscriptionDebugForceFree() =>
      _box.get(_subscriptionDebugForceFreeKey) == 'true';

  Future<void> setSubscriptionDebugForceFree(bool value) =>
      _box.put(_subscriptionDebugForceFreeKey, value.toString());

  int? _getInt(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> _setInt(String key, int? value) =>
      value == null ? _box.delete(key) : _box.put(key, value.toString());

  int? getLimitTextBlock() => _getInt(_limitTextBlockKey);
  Future<void> setLimitTextBlock(int? value) =>
      _setInt(_limitTextBlockKey, value);

  int? getLimitTextSection() => _getInt(_limitTextSectionKey);
  Future<void> setLimitTextSection(int? value) =>
      _setInt(_limitTextSectionKey, value);

  int? getLimitPrompt() => _getInt(_limitPromptKey);
  Future<void> setLimitPrompt(int? value) => _setInt(_limitPromptKey, value);

  int? getLimitTodoItem() => _getInt(_limitTodoItemKey);
  Future<void> setLimitTodoItem(int? value) =>
      _setInt(_limitTodoItemKey, value);

  int? getLimitTodoMaxItems() => _getInt(_limitTodoMaxItemsKey);
  Future<void> setLimitTodoMaxItems(int? value) =>
      _setInt(_limitTodoMaxItemsKey, value);
}
