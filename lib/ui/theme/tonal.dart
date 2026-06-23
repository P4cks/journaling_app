import 'dart:math';

import 'package:flutter/material.dart';

/// Tonal same-hue colour system for coloured blocks (GUS-86).
///
/// A block stores a single base colour (a hue anchor from the post-it
/// palette). Rather than paint that colour raw and flip the text between pure
/// black/white by luminance (the old `contrastOn` approach — legible but
/// visually incoherent across a multi-colour grid), we derive a matched
/// **pair** from the base hue, à la Material's container / onContainer:
///
/// - [tonalBlockBackground] — a soft, low-chroma tint of the hue (a light wash
///   in light themes; a deep muted card in dark themes).
/// - [tonalBlockForeground] — a saturated **same-hue** ink for text + icons,
///   nudged in lightness until it clears a WCAG contrast target against the
///   background.
///
/// The result: every block reads as "one colour, tinted" with confidently
/// legible same-hue text, and the whole grid feels intentional regardless of
/// how many different hues are on screen.

/// The resolved **block ink** — the foreground colour `BlockChrome` injected
/// via `DefaultTextStyle`/`IconTheme` (the tonal same-hue ink on a coloured
/// block, or `onSurface` on a plain card). Blocks that need an explicit colour
/// for a non-text element (a checkbox fill, a divider, a muted caption) should
/// derive it from this — e.g. `blockInk(context).withValues(alpha: 0.6)` — so it
/// tracks the tonal ink instead of pinning `colorScheme.primary`/`onSurface`,
/// which would ignore the block's colour. (GUS-86 per-block audit.)
Color blockInk(BuildContext context) =>
    DefaultTextStyle.of(context).style.color ??
    Theme.of(context).colorScheme.onSurface;

/// WCAG relative contrast ratio between two opaque colours (1–21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = max(la, lb);
  final lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// The tint background for a coloured block, derived from [base]'s hue.
/// [brightness] is the active theme brightness.
Color tonalBlockBackground(Color base, Brightness brightness) {
  final hsl = HSLColor.fromColor(base);
  if (brightness == Brightness.dark) {
    // A deep, muted card that sits a touch above the warm-dark surface.
    return hsl
        .withSaturation((hsl.saturation * 0.55).clamp(0.16, 0.38))
        .withLightness(0.22)
        .toColor();
  }
  // A soft pastel wash — chroma kept modest so text stays the star.
  return hsl
      .withSaturation(hsl.saturation.clamp(0.32, 0.58))
      .withLightness(0.90)
      .toColor();
}

/// The same-hue ink (text + icons) for a coloured block, guaranteed legible
/// against [tonalBlockBackground] for the same [base] / [brightness].
///
/// Starts deep (light theme) or bright (dark theme) and walks the lightness
/// away from the background until the contrast [target] is met, so even a
/// near-grey or awkward mid-tone base resolves to readable text.
Color tonalBlockForeground(
  Color base,
  Brightness brightness, {
  double target = 5.0,
}) {
  final hsl = HSLColor.fromColor(base);
  final bg = tonalBlockBackground(base, brightness);
  final sat = hsl.saturation.clamp(0.45, 0.72);
  final isDark = brightness == Brightness.dark;

  double light = isDark ? 0.82 : 0.26;
  final step = isDark ? 0.02 : -0.02;
  Color fg = hsl.withSaturation(sat).withLightness(light).toColor();

  var guard = 0;
  while (contrastRatio(fg, bg) < target && guard < 48) {
    light = (light + step).clamp(0.0, 1.0);
    fg = hsl.withSaturation(sat).withLightness(light).toColor();
    if (light == 0.0 || light == 1.0) break;
    guard++;
  }
  return fg;
}
