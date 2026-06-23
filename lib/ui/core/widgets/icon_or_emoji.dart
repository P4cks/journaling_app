import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Whether a stored icon-or-emoji value is an emoji glyph rather than a
/// curated icon name (GUS-82).
///
/// Layout (`JournalLayout.iconName`) and habit (`HabitDefinition.iconName`)
/// icons persist a single `String` that holds **either** a curated icon name
/// (an ASCII identifier like `"squaresFour"` / `"sun"`, resolved through a
/// catalogue) **or** an emoji glyph (e.g. `"😀"`, rendered verbatim). Icon
/// names are always pure ASCII; emoji glyphs are always non-ASCII, so the two
/// never collide — the rune check below is unambiguous. This lets the same
/// `String` field carry both without a Hive schema bump.
///
/// An empty string and any all-ASCII value (incl. a name that was removed
/// from a catalogue) read as an icon name, so they keep falling through to
/// the catalogue's default-glyph fallback exactly as before.
bool isEmojiValue(String value) => value.runes.any((r) => r > 0x7F);

/// Renders a stored icon-or-emoji [value] (GUS-82): an emoji glyph as text,
/// or a curated icon resolved through [resolveIcon] and drawn via [AppIcon].
///
/// Each surface passes its own catalogue resolver — `layoutIconFor(v).icon`
/// for layouts, `carouselIconFor(v)?.icon ?? <fallback>` for habits — so the
/// fallback behaviour stays owned by the catalogue. [size] / [color] apply to
/// both branches (the emoji text uses [size] as its font size); when unset the
/// glyph inherits from the surrounding `IconTheme` / `DefaultTextStyle`.
class IconOrEmoji extends StatelessWidget {
  const IconOrEmoji({
    super.key,
    required this.value,
    required this.resolveIcon,
    this.size,
    this.color,
  });

  final String? value;
  final HugeIconData Function(String? value) resolveIcon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v != null && isEmojiValue(v)) {
      return Text(
        v,
        style: TextStyle(fontSize: size, color: color),
        textAlign: TextAlign.center,
      );
    }
    return AppIcon(resolveIcon(v), size: size, color: color);
  }
}
