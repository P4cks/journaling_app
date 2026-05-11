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
  });

  final String id;
  final String displayName;
  final Color seed;
  final Color darkSurface;
  final Color lightSurface;
  final Color defaultSecondary;
  final Color defaultAccent;

  Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;
}

const kSurfacePalettes = <SurfacePalette>[
  SurfacePalette(
    id: 'midnight',
    displayName: 'Midnight',
    seed: Color(0xFF3E4C78),
    darkSurface: Color(0xFF101524),
    lightSurface: Color(0xFFF7F8FC),
    defaultSecondary: Color(0xFF7AA2F7),
    defaultAccent: Color(0xFFFFB86B),
  ),
  SurfacePalette(
    id: 'graphite',
    displayName: 'Graphite',
    seed: Color(0xFF5A5A5F),
    darkSurface: Color(0xFF14161A),
    lightSurface: Color(0xFFF6F6F7),
    defaultSecondary: Color(0xFFB0B6C2),
    defaultAccent: Color(0xFF7DD3FC),
  ),
  SurfacePalette(
    id: 'forest',
    displayName: 'Forest',
    seed: Color(0xFF3F6A52),
    darkSurface: Color(0xFF101A14),
    lightSurface: Color(0xFFF4F8F5),
    defaultSecondary: Color(0xFF94C5A7),
    defaultAccent: Color(0xFFE4B363),
  ),
  SurfacePalette(
    id: 'plum',
    displayName: 'Plum',
    seed: Color(0xFF6E4368),
    darkSurface: Color(0xFF1A1018),
    lightSurface: Color(0xFFFAF5F8),
    defaultSecondary: Color(0xFFD4A6CB),
    defaultAccent: Color(0xFFFFB86B),
  ),
  SurfacePalette(
    id: 'slate',
    displayName: 'Slate',
    seed: Color(0xFF4B6175),
    darkSurface: Color(0xFF111722),
    lightSurface: Color(0xFFF5F7FA),
    defaultSecondary: Color(0xFF9BB1C7),
    defaultAccent: Color(0xFF8EE1C5),
  ),
  SurfacePalette(
    id: 'cocoa',
    displayName: 'Cocoa',
    seed: Color(0xFF6B4A3B),
    darkSurface: Color(0xFF18120E),
    lightSurface: Color(0xFFFBF6F1),
    defaultSecondary: Color(0xFFD2B295),
    defaultAccent: Color(0xFFE6855F),
  ),
];

SurfacePalette paletteById(String? id) {
  for (final p in kSurfacePalettes) {
    if (p.id == id) return p;
  }
  return kSurfacePalettes.first;
}
