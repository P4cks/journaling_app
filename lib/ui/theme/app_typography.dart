import 'package:flutter/material.dart';

/// The app's type system (GUS-84) — the "warm tactile journal" voice.
///
/// Two bundled OFL variable fonts (declared in `pubspec.yaml`):
/// - **Fraunces** (`kDisplayFamily`) — a warm soft-serif for the *journal
///   voice*: entry titles, dates, headings. Carries `opsz` (optical size) and
///   `SOFT` (terminal softness) axes we drive for warmth.
/// - **Inter** (`kBodyFamily`) — a clean humanist sans for *everything the user
///   reads or operates*: entry body text and all UI chrome.
///
/// Both are variable: a single TTF per family carries every weight and Flutter
/// maps `FontWeight` to the `wght` axis. We additionally pass explicit
/// `FontVariation`s so optical size / softness track the rendered size.
///
/// Slot assignment (consumed via `Theme.of(context).textTheme`):
/// - `display* / headline* / titleLarge / titleMedium` → **Fraunces**.
/// - `titleSmall / body* / label*` → **Inter**. (`titleSmall` is a deliberate
///   exception to "all titles are Fraunces": it labels UI chrome — section
///   headers, chips, the Pro badge — where the sans reads cleaner at 13px.)
///
/// For one-off journal-specific styles that don't map cleanly onto a Material
/// slot, use the named [AppText] getters rather than hand-rolling a `TextStyle`.
class AppTypography {
  AppTypography._();
}

/// Font family names — must match the `family:` keys in `pubspec.yaml`.
const String kDisplayFamily = 'Fraunces';
const String kBodyFamily = 'Inter';

// Fraunces axis defaults for the warm tactile voice. `SOFT` rounds the
// terminals (warmth); `WONK` is kept at 0 so letterforms stay calm and
// legible rather than quirky.
const double _kFrauncesSoft = 50;
const double _kFrauncesWonk = 0;

double _wghtValue(FontWeight w) => (FontWeight.values.indexOf(w) + 1) * 100.0;

/// A Fraunces (display) style. [opsz] should track the rendered [size] so the
/// optical-size axis gives the right stroke contrast (small text stays sturdy,
/// large text turns elegant).
TextStyle _fraunces({
  required double size,
  required double opsz,
  FontWeight weight = FontWeight.w600,
  double height = 1.12,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontWeight: weight,
    fontVariations: [
      FontVariation('opsz', opsz),
      FontVariation('SOFT', _kFrauncesSoft),
      FontVariation('WONK', _kFrauncesWonk),
      FontVariation('wght', _wghtValue(weight)),
    ],
  );
}

/// An Inter (body / UI) style.
TextStyle _inter({
  required double size,
  FontWeight weight = FontWeight.w400,
  double height = 1.45,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: kBodyFamily,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', _wghtValue(weight))],
  );
}

/// Builds the app-wide [TextTheme]. Wired into `ThemeData.textTheme` by
/// `buildAppTheme`. Colours are intentionally left null so each slot inherits
/// the palette's `onSurface` (and per-context overrides) at paint time.
TextTheme buildAppTextTheme() {
  return TextTheme(
    // Display — Fraunces, expressive, for the rare hero moment.
    displayLarge: _fraunces(
      size: 40,
      opsz: 96,
      height: 1.05,
      letterSpacing: -0.5,
    ),
    displayMedium: _fraunces(
      size: 32,
      opsz: 72,
      height: 1.08,
      letterSpacing: -0.25,
    ),
    displaySmall: _fraunces(size: 28, opsz: 56, height: 1.1),
    // Headline — Fraunces, section + screen headings.
    headlineLarge: _fraunces(size: 26, opsz: 48, height: 1.15),
    headlineMedium: _fraunces(size: 22, opsz: 36, height: 1.2),
    headlineSmall: _fraunces(size: 19, opsz: 28, height: 1.25),
    // Title — Fraunces for the larger two (content headings)…
    titleLarge: _fraunces(size: 18, opsz: 24, height: 1.25),
    titleMedium: _fraunces(size: 16, opsz: 20, height: 1.3),
    // …Inter for the small UI label (section headers, chips, badges).
    titleSmall: _inter(
      size: 13,
      weight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.1,
    ),
    // Body — Inter, the reading voice.
    bodyLarge: _inter(size: 16, height: 1.5, letterSpacing: 0.15),
    bodyMedium: _inter(size: 14, height: 1.5, letterSpacing: 0.1),
    bodySmall: _inter(size: 12.5, height: 1.45, letterSpacing: 0.1),
    // Label — Inter, controls (buttons inherit labelLarge).
    labelLarge: _inter(
      size: 14.5,
      weight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.1,
    ),
    labelMedium: _inter(
      size: 12,
      weight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.2,
    ),
    labelSmall: _inter(
      size: 11,
      weight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.3,
    ),
  );
}

/// Named journal-specific styles that don't map onto a Material slot. Read
/// these instead of hand-building a `TextStyle` so the type voice stays in one
/// place. Colour is inherited unless the call site overrides it.
class AppText {
  AppText._();

  /// The editable entry title in the journal AppBar — the page's nameplate.
  static TextStyle get entryTitle =>
      _fraunces(size: 28, opsz: 60, height: 1.1, letterSpacing: -0.25);

  /// The date subtitle under the entry title — the journal's quiet dateline.
  static TextStyle get entryDate => _fraunces(
    size: 14.5,
    opsz: 16,
    weight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// A content section heading inside an entry (e.g. a header-section block).
  static TextStyle get sectionHeading =>
      _fraunces(size: 20, opsz: 28, height: 1.2);
}
