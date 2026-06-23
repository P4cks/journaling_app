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
///
/// Warm tactile journal palette (GUS-85): a warm cream surface and a warm
/// near-black ink rather than the old cool greys, with a soft terracotta
/// accent so CTAs / focus read warm instead of fighting the cream.
const kLightDefaultPalette = SurfacePalette(
  id: 'light',
  displayName: 'Light',
  seed: Color(0xFF5A524A),
  brightness: Brightness.light,
  surface: Color(0xFFFAF6EF),
  defaultSecondary: Color(0xFFB6AE9F),
  defaultAccent: Color(0xFFC57B57),
  defaultTextColor: Color(0xFF2B2622),
);

/// Built-in dark default. Free + always selectable (GUS-27 / GUS-26).
///
/// Warm tactile journal palette (GUS-85): a warm near-black surface and a
/// warm off-white ink (not harsh pure white), with a slightly brighter
/// terracotta accent for visibility on the dark ground.
const kDarkDefaultPalette = SurfacePalette(
  id: 'dark',
  displayName: 'Dark',
  seed: Color(0xFF5A524A),
  brightness: Brightness.dark,
  surface: Color(0xFF1A1714),
  defaultSecondary: Color(0xFFB6AE9F),
  defaultAccent: Color(0xFFD98E68),
  defaultTextColor: Color(0xFFF3ECE2),
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
