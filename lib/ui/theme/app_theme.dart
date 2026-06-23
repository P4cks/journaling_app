import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/theme/app_typography.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

/// Builds the single app-wide [ThemeData] from a [palette]. The palette
/// bakes in its own brightness, surface, accent, secondary, and text
/// colour, so there are no override parameters anymore (GUS-27). The
/// container-tier lerp math is unchanged.
ThemeData buildAppTheme(SurfacePalette palette) {
  final brightness = palette.brightness;
  final base = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
  );

  final surface = palette.surface;
  final onSurface = palette.defaultTextColor ?? contrastOn(surface);

  final containerLow = Color.lerp(surface, onSurface, 0.03)!;
  final container = Color.lerp(surface, onSurface, 0.05)!;
  final containerHigh = Color.lerp(surface, onSurface, 0.08)!;
  final containerHighest = Color.lerp(surface, onSurface, 0.12)!;
  final onSurfaceVariant = Color.lerp(onSurface, surface, 0.30)!;

  final effectiveAccent = palette.defaultAccent;
  final effectiveSecondary = palette.defaultSecondary;

  final primaryContainer = Color.lerp(
    surface,
    effectiveAccent,
    brightness == Brightness.dark ? 0.35 : 0.45,
  )!;
  final secondaryContainer = Color.lerp(
    surface,
    effectiveSecondary,
    brightness == Brightness.dark ? 0.30 : 0.40,
  )!;
  final tertiary = Color.lerp(effectiveSecondary, effectiveAccent, 0.4)!;
  final tertiaryContainer = Color.lerp(
    surface,
    tertiary,
    brightness == Brightness.dark ? 0.30 : 0.40,
  )!;

  final scheme = base.copyWith(
    brightness: brightness,
    primary: effectiveAccent,
    onPrimary: contrastOn(effectiveAccent),
    primaryContainer: primaryContainer,
    onPrimaryContainer: contrastOn(primaryContainer),
    secondary: effectiveSecondary,
    onSecondary: contrastOn(effectiveSecondary),
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: contrastOn(secondaryContainer),
    tertiary: tertiary,
    onTertiary: contrastOn(tertiary),
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: contrastOn(tertiaryContainer),
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: surface,
    surfaceContainerLow: containerLow,
    surfaceContainer: container,
    surfaceContainerHigh: containerHigh,
    surfaceContainerHighest: containerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: Color.lerp(onSurface, surface, 0.5)!,
    outlineVariant: Color.lerp(onSurface, surface, 0.7)!,
    shadow: const Color(0xFF000000),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // House type system (GUS-84). `fontFamily` defaults stray `Text` widgets
    // to Inter; the explicit `textTheme` assigns Playfair Display vs Inter per slot.
    // `.apply` tints every slot with the palette's onSurface (our styles carry
    // no colour) so text follows the active palette.
    fontFamily: kBodyFamily,
    textTheme: buildAppTextTheme().apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    iconTheme: IconThemeData(color: scheme.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onPrimaryContainer),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
  );
}
