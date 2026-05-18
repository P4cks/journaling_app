import 'dart:math';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';

/// Replacement for the old `BlockCard`. Wraps a block's content in
/// post-it-style chrome: rotation + offset transforms, palette-driven
/// color, drag scale-up, and live response to the
/// `themeSettings.postItModeEnabled` toggle (when off, falls back to
/// the flat-card look the app shipped with).
///
/// The transforms sit *inside* the tile's layout box — they are visual
/// only. The tile's RenderBox stays axis-aligned, so the drag/insertion
/// math in `BlockGrid` is unaffected.
class PostItBlock extends StatelessWidget {
  const PostItBlock({
    super.key,
    required this.child,
    this.visuals = BlockVisuals.zero,
    this.topRight,
    this.isDragging = false,
  });

  final Widget child;
  final BlockVisuals visuals;
  final Widget? topRight;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final themeSettings = AppDependencies.of(context).themeSettings;
    final postIt = themeSettings.postItModeEnabled;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = postIt
        ? (colorFromHex(visuals.colorHex) ?? scheme.surfaceContainerHigh)
        : scheme.surfaceContainerHigh;
    final fg = postIt && visuals.colorHex != null
        ? contrastOn(bg)
        : scheme.onSurface;

    final radius = postIt ? 16.0 : 14.0;
    final shadowAlpha = isDragging
        ? (isDark ? 0.85 : 0.32)
        : (isDark ? 0.55 : 0.18);
    final shadowBlur = isDragging ? 24.0 : 14.0;
    final shadowDy = isDragging ? 10.0 : 4.0;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: shadowAlpha),
            blurRadius: shadowBlur,
            spreadRadius: 0,
            offset: Offset(0, shadowDy),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: Stack(
            children: [
              Padding(padding: const EdgeInsets.all(12), child: child),
              if (topRight != null) Positioned(top: 4, right: 4, child: topRight!),
            ],
          ),
        ),
      ),
    );

    if (!postIt) {
      return card;
    }

    return Transform.translate(
      offset: Offset(visuals.offsetX.toDouble(), visuals.offsetY.toDouble()),
      child: Transform.rotate(
        angle: visuals.rotationDeg * pi / 180,
        child: AnimatedScale(
          scale: isDragging ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: card,
        ),
      ),
    );
  }
}
