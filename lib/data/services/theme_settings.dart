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
    : _customPalettes = _decodeCustomPalettes(
        _settings.getThemeCustomPalettes(),
      ),
      _paletteId = _resolvePaletteId(
        _settings.getThemePaletteId(),
        _decodeCustomPalettes(_settings.getThemeCustomPalettes()),
      ),
      _blockRotationEnabled = _settings.getThemeBlockRotation() ?? true,
      _blockOffsetEnabled = _settings.getThemeBlockOffset() ?? true,
      _blockColorEnabled = _settings.getThemeBlockColor() ?? true,
      _postItPalette = _decodePostItPalette(_settings.getThemePostItPalette());

  final SettingsStorageService _settings;

  String _paletteId;
  List<SurfacePalette> _customPalettes;
  bool _blockRotationEnabled;
  bool _blockOffsetEnabled;
  bool _blockColorEnabled;
  List<String> _postItPalette;

  String get paletteId => _paletteId;

  /// Built-in Light + Dark defaults followed by the user's custom themes.
  List<SurfacePalette> get palettes => [
    ...kBuiltInPalettes,
    ..._customPalettes,
  ];
  List<SurfacePalette> get customPalettes => List.unmodifiable(_customPalettes);

  /// The currently-selected theme. The palette's baked-in brightness +
  /// surface drive the whole app (GUS-27); there is no app-wide
  /// light/dark mode anymore.
  SurfacePalette get palette {
    for (final p in palettes) {
      if (p.id == _paletteId) return p;
    }
    return kLightDefaultPalette;
  }

  bool get selectedPaletteIsCustom => palette.isCustom;

  /// Whether each block is rendered with a slight per-block rotation.
  bool get blockRotationEnabled => _blockRotationEnabled;

  /// Whether each block is nudged off-center by its per-block offset.
  bool get blockOffsetEnabled => _blockOffsetEnabled;

  /// Whether each block is tinted with its per-block palette color.
  bool get blockColorEnabled => _blockColorEnabled;

  /// Hex strings of the user-configured post-it color palette. Empty when
  /// the user has cleared every color; new entries materialize with no
  /// `colorHex` and the block falls back to `surfaceContainerHigh`.
  List<String> get postItPalette => List.unmodifiable(_postItPalette);

  Future<void> setBlockRotationEnabled(bool value) async {
    if (_blockRotationEnabled == value) return;
    _blockRotationEnabled = value;
    debugPrint('[ThemeSettings] blockRotationEnabled -> $value');
    await _settings.setThemeBlockRotation(value);
    notifyListeners();
  }

  Future<void> setBlockOffsetEnabled(bool value) async {
    if (_blockOffsetEnabled == value) return;
    _blockOffsetEnabled = value;
    debugPrint('[ThemeSettings] blockOffsetEnabled -> $value');
    await _settings.setThemeBlockOffset(value);
    notifyListeners();
  }

  Future<void> setBlockColorEnabled(bool value) async {
    if (_blockColorEnabled == value) return;
    _blockColorEnabled = value;
    debugPrint('[ThemeSettings] blockColorEnabled -> $value');
    await _settings.setThemeBlockColor(value);
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

  Future<void> setPaletteId(String id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    debugPrint('[ThemeSettings] paletteId -> $id');
    await _settings.setThemePaletteId(id);
    notifyListeners();
  }

  Future<void> addCustomPalette(SurfacePalette palette) async {
    if (!palette.isCustom) return;
    final next = [..._customPalettes, palette];
    _customPalettes = next;
    _paletteId = palette.id;
    debugPrint('[ThemeSettings] customPalette.${palette.id} -> added');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    await _settings.setThemePaletteId(palette.id);
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
    debugPrint('[ThemeSettings] customPalette.${palette.id} -> updated');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    notifyListeners();
  }

  Future<void> deleteCustomPalette(String id) async {
    final next = _customPalettes.where((palette) => palette.id != id).toList();
    if (next.length == _customPalettes.length) return;
    _customPalettes = next;
    if (_paletteId == id) {
      _paletteId = kLightDefaultPalette.id;
      await _settings.setThemePaletteId(_paletteId);
    }
    debugPrint('[ThemeSettings] customPalette.$id -> deleted');
    await _settings.setThemeCustomPalettes(_encodeCustomPalettes(next));
    notifyListeners();
  }

  /// A blank custom-palette template for the theme editor. New custom
  /// themes default to dark brightness (matches the prior editor default).
  SurfacePalette customPaletteTemplate({String? id}) {
    return SurfacePalette(
      id: id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
      displayName: 'New theme',
      seed: kDarkDefaultPalette.defaultAccent,
      brightness: Brightness.dark,
      surface: kDarkDefaultPalette.surface,
      defaultSecondary: kDarkDefaultPalette.defaultSecondary,
      defaultAccent: kDarkDefaultPalette.defaultAccent,
      defaultTextColor: const Color(0xFFFFFFFF),
      isCustom: true,
    );
  }

  static String _resolvePaletteId(
    String? raw,
    List<SurfacePalette> customPalettes,
  ) {
    for (final palette in kBuiltInPalettes) {
      if (palette.id == raw) return palette.id;
    }
    for (final palette in customPalettes) {
      if (palette.id == raw) return palette.id;
    }
    return kLightDefaultPalette.id;
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
    final id = _stringValue(data['id']) ?? 'custom-${data.hashCode}';
    final surface =
        colorFromHex(_stringValue(data['surface'])) ??
        kDarkDefaultPalette.surface;
    final secondary =
        colorFromHex(_stringValue(data['secondary'])) ??
        kDarkDefaultPalette.defaultSecondary;
    final accent =
        colorFromHex(_stringValue(data['accent'])) ??
        kDarkDefaultPalette.defaultAccent;
    final textColor =
        colorFromHex(_stringValue(data['text'])) ?? contrastOn(surface);
    // Decode brightness tolerantly: explicit 'light'/'dark' wins,
    // otherwise infer from the surface's luminance.
    final rawBrightness = _stringValue(data['brightness']);
    final brightness = switch (rawBrightness) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => surface.computeLuminance() > 0.5
          ? Brightness.light
          : Brightness.dark,
    };
    return SurfacePalette(
      id: id,
      displayName: _stringValue(data['name']) ?? 'Custom theme',
      seed: accent,
      brightness: brightness,
      surface: surface,
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
          'brightness': palette.brightness == Brightness.dark
              ? 'dark'
              : 'light',
          'surface': colorToHex(palette.surface),
          'secondary': colorToHex(palette.defaultSecondary),
          'accent': colorToHex(palette.defaultAccent),
          'text': colorToHex(
            palette.defaultTextColor ?? contrastOn(palette.surface),
          ),
        },
    ];
    return jsonEncode(encoded);
  }
}
