import 'dart:convert';
import 'dart:math';

class BlockVisuals {
  final double rotationDeg;
  final int offsetX;
  final int offsetY;
  final String? colorHex;

  const BlockVisuals({
    this.rotationDeg = 0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.colorHex,
  });

  static const BlockVisuals zero = BlockVisuals();

  bool get isZero =>
      rotationDeg == 0 && offsetX == 0 && offsetY == 0 && colorHex == null;

  factory BlockVisuals.fromMap(Map<String, dynamic> map) {
    final rot = map['rot'];
    final dx = map['dx'];
    final dy = map['dy'];
    final color = map['color'];
    return BlockVisuals(
      rotationDeg: rot is num ? rot.toDouble().clamp(-2.0, 2.0) : 0,
      offsetX: dx is num ? dx.toInt().clamp(-4, 4) : 0,
      offsetY: dy is num ? dy.toInt().clamp(-4, 4) : 0,
      colorHex: color is String && color.isNotEmpty ? color : null,
    );
  }

  factory BlockVisuals.fromJson(String? json) {
    if (json == null || json.isEmpty || json == '{}') return zero;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return BlockVisuals.fromMap(decoded);
      return zero;
    } catch (_) {
      return zero;
    }
  }

  Map<String, dynamic> toMap() => {
    if (rotationDeg != 0) 'rot': _round(rotationDeg, 3),
    if (offsetX != 0) 'dx': offsetX,
    if (offsetY != 0) 'dy': offsetY,
    if (colorHex != null) 'color': colorHex,
  };

  String toJson() => jsonEncode(toMap());

  static BlockVisuals random(Random rng, List<String> paletteHex) {
    final rot = (rng.nextDouble() * 4) - 2;
    final dx = rng.nextInt(9) - 4;
    final dy = rng.nextInt(9) - 4;
    final color = paletteHex.isEmpty
        ? null
        : paletteHex[rng.nextInt(paletteHex.length)];
    return BlockVisuals(
      rotationDeg: rot,
      offsetX: dx,
      offsetY: dy,
      colorHex: color,
    );
  }

  static double _round(double v, int decimals) {
    final factor = pow(10, decimals);
    return (v * factor).round() / factor;
  }
}
