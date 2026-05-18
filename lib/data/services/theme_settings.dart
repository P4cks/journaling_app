import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

/// Default post-it palette seeded on first run when the user has not
/// picked their own colors yet. Muted pastels chosen to read against
/// both light and dark themes.
const List<String> kDefaultPostItPalette = [
  '#FFE066',
  '#FFADAD',
  '#FFD6A5',
  '#CAFFBF',
  '#9BF6FF',
  '#BDB2FF',
  '#FFC6FF',
];

class ThemeSettings extends ChangeNotifier {
  ThemeSettings(this._settings)
    : _themeMode = _parseMode(_settings.getThemeMode()),
      _customPalettes = _decodeCustomPalettes(
        _settings.getThemeCustomPalettes(),
      ),
      _paletteId = _resolvePaletteId(
        _settings.getThemePaletteId(),
        _decodeCustomPalettes(_settings.getThemeCustomPalettes()),
      ),
      _secondaryOverride = colorFromHex(_settings.getThemeSecondary()),
      _accentOverride = colorFromHex(_settings.getThemeAccent()),
      _debugSurfaceOverride = colorFromHex(_settings.getThemeDebugSurface()),
      _postItModeEnabled = _settings.getThemePostItMode() ?? true,
      _postItPalette = _decodePostItPalette(_settings.getThemePostItPalette());

  final SettingsStorageService _settings;

  ThemeMode _themeMode;
  String _paletteId;
  List<SurfacePalette> _customPalettes;
  Color? _secondaryOverride;
  Color? _accentOverride;
  Color? _debugSurfaceOverride;
  bool _postItModeEnabled;
  List<String> _postItPalette;

  ThemeMode get themeMode => _themeMode;
  String get paletteId => _paletteId;
  List<SurfacePalette> get palettes => [
    kDefaultSurfacePalette,
    ..._customPalettes,
  ];
  List<SurfacePalette> get customPalettes => List.unmodifiable(_customPalettes);
  SurfacePalette get palette {
    for (final p in palettes) {
      if (p.id == _paletteId) return p;
    }
    return kDefaultSurfacePalette;
  }

  bool get selectedPaletteIsCustom => palette.isCustom;
  Color? get secondaryOverride => _secondaryOverride;
  Color? get accentOverride => _accentOverride;
  Color? get debugSurfaceOverride => _debugSurfaceOverride;

  Color get effectiveSecondary =>
      _secondaryOverride ?? palette.defaultSecondary;
  Color get effectiveAccent => _accentOverride ?? palette.defaultAccent;

  bool get postItModeEnabled => _postItModeEnabled;

  /// Hex strings of the user-configured post-it color palette. Empty when
  /// the user has cleared every color; new entries materialize with no
  /// `colorHex` and the block falls back to `surfaceContainerHigh`.
  List<String> get postItPalette => List.unmodifiable(_postItPalette);

  Future<void> setPostItModeEnabled(bool value) async {
    if (_postItModeEnabled == value) return;
    _postItModeEnabled = value;
    debugPrint('[ThemeSettings] postItModeEnabled -> $value');
    await _settings.setThemePostItMode(value);
    notifyListeners();
  }

  Future<void> addPostItColor(Color color) async {
    final hex = colorToHex(color);
    if (_postItPalette.contains(hex)) return;
    _postItPalette = [..._postItPalette, hex];
    debugPrint('[ThemeSettings] postItPalette += $hex');
    await _settings.setThemePostItPalette(jsonEncode(_postItPalette));
    notifyListeners();
  }

  Future<void> removePostItColorAt(int index) async {
    if (index < 0 || index >= _postItPalette.length) return;
    final next = [..._postItPalette]..removeAt(index);
    _postItPalette = next;
    debugPrint('[ThemeSettings] postItPalette[$index] -> removed');
    await _settings.setThemePostItPalette(
      next.isEmpty ? null : jsonEncode(next),
    );
    notifyListeners();
  }

  Future<void> setPostItPalette(List<Color> colors) async {
    final next = [for (final c in colors) colorToHex(c)];
    _postItPalette = next;
    debugPrint('[ThemeSettings] postItPalette -> ${next.length} entries');
    await _settings.setThemePostItPalette(
      next.isEmpty ? null : jsonEncode(next),
    );
    notifyListeners();
  }

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
    _secondaryOverride = null;
    _accentOverride = null;
    debugPrint('[ThemeSettings] paletteId -> $id');
    await _settings.setThemePaletteId(id);
    await _settings.setThemeSecondary(null);
    await _settings.setThemeAccent(null);
    notifyListeners();
  }

  Future<void> addCustomPalette(SurfacePalette palette) async {
    if (!palette.isCustom) return;
    final next = [..._customPalettes, palette];
    _customPalettes = next;
    _secondaryOverride = null;
    _accentOverride = null;
    _paletteId = palette.id;
    debugPrint('[ThemeSettings] customPalette.${palette.id} -> added');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    await _settings.setThemePaletteId(palette.id);
    await _settings.setThemeSecondary(null);
    await _settings.setThemeAccent(null);
    notifyListeners();
  }

  Future<void> updateCustomPalette(SurfacePalette palette) async {
    if (!palette.isCustom) return;
    final next = [
      for (final existing in _customPalettes)
        existing.id == palette.id ? palette : existing,
    ];
    if (!next.any((p) => p.id == palette.id)) return;
    _customPalettes = next;
    _secondaryOverride = null;
    _accentOverride = null;
    debugPrint('[ThemeSettings] customPalette.${palette.id} -> updated');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    await _settings.setThemeSecondary(null);
    await _settings.setThemeAccent(null);
    notifyListeners();
  }

  Future<void> deleteCustomPalette(String id) async {
    final next = _customPalettes.where((palette) => palette.id != id).toList();
    if (next.length == _customPalettes.length) return;
    _customPalettes = next;
    if (_paletteId == id) {
      _paletteId = kDefaultSurfacePalette.id;
      await _settings.setThemePaletteId(_paletteId);
    }
    _secondaryOverride = null;
    _accentOverride = null;
    debugPrint('[ThemeSettings] customPalette.$id -> deleted');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    await _settings.setThemeSecondary(null);
    await _settings.setThemeAccent(null);
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

  SurfacePalette customPaletteTemplate({String? id}) {
    final surface = kDefaultSurfacePalette.surfaceFor(Brightness.dark);
    return SurfacePalette(
      id: id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
      displayName: 'New theme',
      seed: kDefaultSurfacePalette.defaultAccent,
      darkSurface: surface,
      lightSurface: surface,
      defaultSecondary: kDefaultSurfacePalette.defaultSecondary,
      defaultAccent: kDefaultSurfacePalette.defaultAccent,
      defaultTextColor: const Color(0xFFFFFFFF),
      isCustom: true,
    );
  }

  static String _resolvePaletteId(
    String? raw,
    List<SurfacePalette> customPalettes,
  ) {
    for (final palette in kSurfacePalettes) {
      if (palette.id == raw) return palette.id;
    }
    for (final palette in customPalettes) {
      if (palette.id == raw) return palette.id;
    }
    return kDefaultSurfacePalette.id;
  }

  static List<SurfacePalette> _decodeCustomPalettes(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is Map)
              _decodeCustomPalette(Map<String, dynamic>.from(item)),
        ];
      }
      if (decoded is Map<String, dynamic>) {
        return [
          for (final entry in decoded.entries)
            if (entry.value is Map)
              _decodeLegacyCustomPalette(
                entry.key,
                Map<String, dynamic>.from(entry.value as Map),
              ),
        ];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static SurfacePalette _decodeCustomPalette(Map<String, dynamic> data) {
    final fallback = kDefaultSurfacePalette;
    final id = _stringValue(data['id']) ?? 'custom-${data.hashCode}';
    final surface =
        colorFromHex(_stringValue(data['surface'])) ??
        fallback.surfaceFor(Brightness.dark);
    final secondary =
        colorFromHex(_stringValue(data['secondary'])) ??
        fallback.defaultSecondary;
    final accent =
        colorFromHex(_stringValue(data['accent'])) ?? fallback.defaultAccent;
    final textColor =
        colorFromHex(_stringValue(data['text'])) ??
        fallback.defaultTextColor ??
        contrastOn(surface);
    return SurfacePalette(
      id: id,
      displayName: _stringValue(data['name']) ?? 'Custom theme',
      seed: accent,
      darkSurface: surface,
      lightSurface: surface,
      defaultSecondary: secondary,
      defaultAccent: accent,
      defaultTextColor: textColor,
      isCustom: true,
    );
  }

  static SurfacePalette _decodeLegacyCustomPalette(
    String id,
    Map<String, dynamic> data,
  ) {
    return _decodeCustomPalette({
      'id': id,
      'name': switch (id) {
        'custom1' => 'Custom 1',
        'custom2' => 'Custom 2',
        'custom3' => 'Custom 3',
        _ => 'Custom theme',
      },
      ...data,
    });
  }

  static String? _stringValue(Object? value) => value is String ? value : null;

  static List<String> _decodePostItPalette(String? raw) {
    if (raw == null || raw.isEmpty) return List.of(kDefaultPostItPalette);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is String && item.isNotEmpty) item,
        ];
      }
    } catch (_) {}
    return List.of(kDefaultPostItPalette);
  }

  static String _encodeCustomPalettes(List<SurfacePalette> palettes) {
    final encoded = [
      for (final palette in palettes)
        {
          'id': palette.id,
          'name': palette.displayName,
          'surface': colorToHex(palette.surfaceFor(Brightness.dark)),
          'secondary': colorToHex(palette.defaultSecondary),
          'accent': colorToHex(palette.defaultAccent),
          'text': colorToHex(
            palette.defaultTextColor ??
                contrastOn(palette.surfaceFor(Brightness.dark)),
          ),
        },
    ];
    return jsonEncode(encoded);
  }
}
