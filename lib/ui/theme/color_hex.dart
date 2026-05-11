import 'package:flutter/material.dart';

String colorToHex(Color color) {
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

Color? colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var v = hex.trim();
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final parsed = int.tryParse(v, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

Color contrastOn(Color color) =>
    color.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
