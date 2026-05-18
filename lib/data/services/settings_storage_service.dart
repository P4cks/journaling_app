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
  static const _blockTextCharLimitKey = 'block.text.charLimit';
  static const _blockMoodTitleKey = 'block.mood.title';
  static const _blockWeatherTitleKey = 'block.weather.title';
  static const _blockCustomCarouselDefinitionsKey =
      'block.customCarousel.definitions';
  static const _themePostItModeKey = 'theme.postItMode';
  static const _themePostItPaletteKey = 'theme.postItPalette';

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

  String? getBlockTextCharLimit() => _box.get(_blockTextCharLimitKey);

  Future<void> setBlockTextCharLimit(int? value) => value == null
      ? _box.delete(_blockTextCharLimitKey)
      : _box.put(_blockTextCharLimitKey, value.toString());

  String? getBlockMoodTitle() => _box.get(_blockMoodTitleKey);

  Future<void> setBlockMoodTitle(String? value) =>
      (value == null || value.isEmpty)
          ? _box.delete(_blockMoodTitleKey)
          : _box.put(_blockMoodTitleKey, value);

  String? getBlockWeatherTitle() => _box.get(_blockWeatherTitleKey);

  Future<void> setBlockWeatherTitle(String? value) =>
      (value == null || value.isEmpty)
          ? _box.delete(_blockWeatherTitleKey)
          : _box.put(_blockWeatherTitleKey, value);

  String? getBlockCustomCarouselDefinitionsJson() =>
      _box.get(_blockCustomCarouselDefinitionsKey);

  Future<void> setBlockCustomCarouselDefinitionsJson(String? json) =>
      (json == null || json.isEmpty)
          ? _box.delete(_blockCustomCarouselDefinitionsKey)
          : _box.put(_blockCustomCarouselDefinitionsKey, json);

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
}
