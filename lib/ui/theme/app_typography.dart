import 'package:flutter/material.dart';

/// The app's type system (GUS-84) — the "warm tactile journal" voice.
///
/// Two bundled OFL variable fonts (declared in `pubspec.yaml`):
/// - **Playfair Display** (`kDisplayFamily`) — a high-contrast transitional
///   serif for the *journal voice*: entry titles, dates, headings. Elegant and
///   editorial; carries a single `wght` axis.
/// - **Inter** (`kBodyFamily`) — a clean humanist sans for *everything the user
///   reads or operates*: entry body text and all UI chrome.
///
/// Both are variable: a single TTF per family carries every weight and Flutter
/// maps `FontWeight` to the `wght` axis (we also pass it explicitly as a
/// `FontVariation` for predictable rendering).
///
/// Slot assignment (consumed via `Theme.of(context).textTheme`):
/// - `display* / headline* / titleLarge / titleMedium` → **Playfair Display**.
/// - `titleSmall / body* / label*` → **Inter**. (`titleSmall` is a deliberate
///   exception to "all titles are display": it labels UI chrome — section
///   headers, chips, the Pro badge — where the sans reads cleaner at 13px.)
///
/// Playfair Display is a *display* face: its thin strokes need size to breathe,
/// so the smaller display slots carry a heavier weight (w600) to keep the
/// hairlines from disappearing.
///
/// For one-off journal-specific styles that don't map cleanly onto a Material
/// slot, use the named [AppText] getters rather than hand-rolling a `TextStyle`.
class AppTypography {
  AppTypography._();
}

/// Font family names — must match the `family:` keys in `pubspec.yaml`.
const String kDisplayFamily = 'Playfair Display';
const String kBodyFamily = 'Inter';

double _wghtValue(FontWeight w) => (FontWeight.values.indexOf(w) + 1) * 100.0;

/// A Playfair Display (display) style. Defaults to w600 so the high-contrast
/// strokes stay legible at the smaller display sizes.
TextStyle _display({
  required double size,
  FontWeight weight = FontWeight.w600,
  double height = 1.15,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', _wghtValue(weight))],
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
    // Display — Playfair Display, expressive, for the rare hero moment.
    displayLarge: _display(size: 40, height: 1.05, letterSpacing: -0.5),
    displayMedium: _display(size: 32, height: 1.08, letterSpacing: -0.25),
    displaySmall: _display(size: 28, height: 1.1),
    // Headline — Playfair Display, section + screen headings.
    headlineLarge: _display(size: 26, height: 1.15),
    headlineMedium: _display(size: 22, height: 1.2),
    headlineSmall: _display(size: 19, height: 1.25),
    // Title — Playfair Display for the larger two (content headings)…
    titleLarge: _display(size: 18, height: 1.25),
    titleMedium: _display(size: 16, height: 1.3),
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
      _display(size: 28, height: 1.1, letterSpacing: -0.25);

  /// The date subtitle under the entry title — the journal's quiet dateline.
  /// A touch heavier so Playfair's hairlines hold up at this small size.
  static TextStyle get entryDate => _display(
    size: 14.5,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// A content section heading inside an entry (e.g. a header-section block).
  static TextStyle get sectionHeading => _display(size: 20, height: 1.2);
}
