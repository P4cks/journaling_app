import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

class ThemeSettings extends ChangeNotifier {
  ThemeSettings(this._settings)
      : _themeMode = _parseMode(_settings.getThemeMode()),
        _paletteId = _settings.getThemePaletteId() ?? kSurfacePalettes.first.id,
        _secondaryOverride = colorFromHex(_settings.getThemeSecondary()),
        _accentOverride = colorFromHex(_settings.getThemeAccent()),
        _debugSurfaceOverride = colorFromHex(_settings.getThemeDebugSurface());

  final SettingsStorageService _settings;

  ThemeMode _themeMode;
  String _paletteId;
  Color? _secondaryOverride;
  Color? _accentOverride;
  Color? _debugSurfaceOverride;

  ThemeMode get themeMode => _themeMode;
  String get paletteId => _paletteId;
  SurfacePalette get palette => paletteById(_paletteId);
  Color? get secondaryOverride => _secondaryOverride;
  Color? get accentOverride => _accentOverride;
  Color? get debugSurfaceOverride => _debugSurfaceOverride;

  Color get effectiveSecondary =>
      _secondaryOverride ?? palette.defaultSecondary;
  Color get effectiveAccent => _accentOverride ?? palette.defaultAccent;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    debugPrint('[ThemeSettings] themeMode -> $mode');
    await _settings.setThemeMode(_encodeMode(mode));
    notifyListeners();
  }

  Future<void> setPaletteId(String id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    debugPrint('[ThemeSettings] paletteId -> $id');
    await _settings.setThemePaletteId(id);
    notifyListeners();
  }

  Future<void> setSecondaryOverride(Color? color) async {
    if (_secondaryOverride == color) return;
    _secondaryOverride = color;
    debugPrint('[ThemeSettings] secondaryOverride -> $color');
    await _settings.setThemeSecondary(color == null ? null : colorToHex(color));
    notifyListeners();
  }

  Future<void> setAccentOverride(Color? color) async {
    if (_accentOverride == color) return;
    _accentOverride = color;
    debugPrint('[ThemeSettings] accentOverride -> $color');
    await _settings.setThemeAccent(color == null ? null : colorToHex(color));
    notifyListeners();
  }

  Future<void> setDebugSurfaceOverride(Color? color) async {
    if (_debugSurfaceOverride == color) return;
    _debugSurfaceOverride = color;
    debugPrint('[ThemeSettings] debugSurfaceOverride -> $color');
    await _settings.setThemeDebugSurface(
      color == null ? null : colorToHex(color),
    );
    notifyListeners();
  }

  static ThemeMode _parseMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _encodeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
