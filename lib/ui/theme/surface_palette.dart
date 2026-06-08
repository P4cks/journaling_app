import 'package:flutter/material.dart';

/// A theme definition. Each palette bakes in its own [brightness] and a
/// single [surface] color — there is no separate light/dark surface pair
/// and no app-wide light/dark mode anymore (GUS-27). Selecting a palette
/// is what flips the whole app between light and dark.
class SurfacePalette {
  const SurfacePalette({
    required this.id,
    required this.displayName,
    required this.seed,
    required this.brightness,
    required this.surface,
    required this.defaultSecondary,
    required this.defaultAccent,
    this.defaultTextColor,
    this.isCustom = false,
  });

  final String id;
  final String displayName;
  final Color seed;
  final Brightness brightness;
  final Color surface;
  final Color defaultSecondary;
  final Color defaultAccent;
  final Color? defaultTextColor;
  final bool isCustom;

  SurfacePalette copyWith({
    String? displayName,
    Color? seed,
    Brightness? brightness,
    Color? surface,
    Color? defaultSecondary,
    Color? defaultAccent,
    Color? defaultTextColor,
    bool? isCustom,
  }) {
    return SurfacePalette(
      id: id,
      displayName: displayName ?? this.displayName,
      seed: seed ?? this.seed,
      brightness: brightness ?? this.brightness,
      surface: surface ?? this.surface,
      defaultSecondary: defaultSecondary ?? this.defaultSecondary,
      defaultAccent: defaultAccent ?? this.defaultAccent,
      defaultTextColor: defaultTextColor ?? this.defaultTextColor,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Built-in light default. Free + always selectable (GUS-27 / GUS-26).
const kLightDefaultPalette = SurfacePalette(
  id: 'light',
  displayName: 'Light',
  seed: Color(0xFF5A5A5F),
  brightness: Brightness.light,
  surface: Color(0xFFF6F6F7),
  defaultSecondary: Color(0xFFB0B6C2),
  defaultAccent: Color(0xFF7DD3FC),
  defaultTextColor: Color(0xFF14161A),
);

/// Built-in dark default. Free + always selectable (GUS-27 / GUS-26).
const kDarkDefaultPalette = SurfacePalette(
  id: 'dark',
  displayName: 'Dark',
  seed: Color(0xFF5A5A5F),
  brightness: Brightness.dark,
  surface: Color(0xFF14161A),
  defaultSecondary: Color(0xFFB0B6C2),
  defaultAccent: Color(0xFF7DD3FC),
  defaultTextColor: Color(0xFFFFFFFF),
);

/// The two built-in defaults, in display order. Custom palettes are
/// appended after these by `ThemeSettings`.
const kBuiltInPalettes = <SurfacePalette>[
  kLightDefaultPalette,
  kDarkDefaultPalette,
];

SurfacePalette paletteById(String? id) {
  for (final p in kBuiltInPalettes) {
    if (p.id == id) return p;
  }
  return kLightDefaultPalette;
}
