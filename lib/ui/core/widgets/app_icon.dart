import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Convenience alias for the SVG-JSON data shape that the HugeIcons
/// constants (e.g. `HugeIcons.strokeRoundedHome01`) expose. Used
/// throughout the UI to type icon parameters without leaking the raw
/// `List<List<dynamic>>` everywhere.
typedef HugeIconData = List<List<dynamic>>;

/// Thin wrapper around [HugeIcon] that inherits `size` and `color` from
/// the surrounding [IconTheme] when not specified explicitly.
///
/// The free HugeIcons package ships only the `strokeRounded` family, so
/// there is no separate "filled" / "active" variant — selected states
/// should be expressed via colour (e.g. `colorScheme.primary`) rather
/// than swapping the icon. Pass any `HugeIcons.strokeRoundedXxx`
/// constant as the [icon].
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color});

  final HugeIconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      size: size ?? iconTheme.size,
      color: color ?? iconTheme.color ?? const Color(0xFF000000),
    );
  }
}
