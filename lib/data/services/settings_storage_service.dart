import 'package:hive_ce/hive.dart';

class SettingsStorageService {
  static const _defaultLayoutIdKey = 'defaultLayoutId';
  static const _unlockAllDaysKey = 'debug.unlockAllDays';
  static const _themeModeKey = 'theme.mode';
  static const _themePaletteIdKey = 'theme.paletteId';
  static const _themeSecondaryKey = 'theme.secondary';
  static const _themeAccentKey = 'theme.accent';
  static const _themeDebugSurfaceKey = 'theme.debugSurface';

  final Box<String> _box;

  SettingsStorageService(this._box);

  String? getDefaultLayoutId() => _box.get(_defaultLayoutIdKey);

  Future<void> setDefaultLayoutId(String id) =>
      _box.put(_defaultLayoutIdKey, id);

  Future<void> clearDefaultLayoutId() => _box.delete(_defaultLayoutIdKey);

  bool getUnlockAllDays() => _box.get(_unlockAllDaysKey) == 'true';

  Future<void> setUnlockAllDays(bool value) =>
      _box.put(_unlockAllDaysKey, value.toString());

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

  String? getThemeDebugSurface() => _box.get(_themeDebugSurfaceKey);

  Future<void> setThemeDebugSurface(String? hex) => hex == null
      ? _box.delete(_themeDebugSurfaceKey)
      : _box.put(_themeDebugSurfaceKey, hex);
}
