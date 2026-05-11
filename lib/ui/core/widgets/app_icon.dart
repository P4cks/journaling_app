import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Thin wrapper around [PhosphorIcon] that wires the duotone secondary tone
/// to the current theme's accent (`colorScheme.primary`) and inherits the
/// primary tone from the surrounding [IconTheme].
///
/// Pass a [PhosphorIconsDuotone].xxx icon for default detail-rich rendering,
/// or a [PhosphorIconsFill].xxx icon for active/selected states.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.secondaryColor,
    this.secondaryOpacity = 1.0,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final Color? secondaryColor;
  final double secondaryOpacity;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PhosphorIcon(
      icon,
      size: size ?? iconTheme.size,
      color: color ?? iconTheme.color,
      duotoneSecondaryColor: secondaryColor ?? scheme.primary,
      duotoneSecondaryOpacity: secondaryOpacity,
    );
  }
}
