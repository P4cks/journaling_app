import 'package:flutter/material.dart';

class SurfacePalette {
  const SurfacePalette({
    required this.id,
    required this.displayName,
    required this.seed,
    required this.darkSurface,
    required this.lightSurface,
    required this.defaultSecondary,
    required this.defaultAccent,
    this.defaultTextColor,
    this.isCustom = false,
  });

  final String id;
  final String displayName;
  final Color seed;
  final Color darkSurface;
  final Color lightSurface;
  final Color defaultSecondary;
  final Color defaultAccent;
  final Color? defaultTextColor;
  final bool isCustom;

  Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  SurfacePalette copyWith({
    String? displayName,
    Color? seed,
    Color? darkSurface,
    Color? lightSurface,
    Color? defaultSecondary,
    Color? defaultAccent,
    Color? defaultTextColor,
    bool? isCustom,
  }) {
    return SurfacePalette(
      id: id,
      displayName: displayName ?? this.displayName,
      seed: seed ?? this.seed,
      darkSurface: darkSurface ?? this.darkSurface,
      lightSurface: lightSurface ?? this.lightSurface,
      defaultSecondary: defaultSecondary ?? this.defaultSecondary,
      defaultAccent: defaultAccent ?? this.defaultAccent,
      defaultTextColor: defaultTextColor ?? this.defaultTextColor,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

const kDefaultSurfacePalette = SurfacePalette(
  id: 'graphite',
  displayName: 'Graphite',
  seed: Color(0xFF5A5A5F),
  darkSurface: Color(0xFF14161A),
  lightSurface: Color(0xFFF6F6F7),
  defaultSecondary: Color(0xFFB0B6C2),
  defaultAccent: Color(0xFF7DD3FC),
);

const kSurfacePalettes = <SurfacePalette>[kDefaultSurfacePalette];

SurfacePalette paletteById(String? id) {
  for (final p in kSurfacePalettes) {
    if (p.id == id) return p;
  }
  return kDefaultSurfacePalette;
}
