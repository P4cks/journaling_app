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
/// The tap-wiggle feedback is currently disabled — see the commented
/// `_wiggle` block below. It may be reinstated once the new
/// double-tap-to-edit gesture model has settled.
///
/// The transforms sit *inside* the tile's layout box — they are visual
/// only. The tile's RenderBox stays axis-aligned, so the drag/insertion
/// math in `BlockGrid` is unaffected.
class PostItBlock extends StatefulWidget {
  const PostItBlock({
    super.key,
    required this.child,
    this.visuals = BlockVisuals.zero,
    this.topRight,
    this.isDragging = false,
    this.isEditing = false,
  });

  final Widget child;
  final BlockVisuals visuals;
  final Widget? topRight;
  final bool isDragging;

  /// True when this block is the active in-place editing target (the
  /// "expand on edit" setting is OFF). Renders a subtle scale + a 2 px
  /// accent-coloured outline so the user can see which block they're
  /// editing. Ignored when [isDragging] is true (drag visuals win).
  final bool isEditing;

  @override
  State<PostItBlock> createState() => _PostItBlockState();
}


class _PostItBlockState extends State<PostItBlock> {
  // Wiggle animation disabled — kept commented out so we can reinstate
  // it after the double-tap-to-edit UX has settled. To revive:
  //   1. Re-add `with SingleTickerProviderStateMixin` to the State class.
  //   2. Restore the fields, initState, dispose, and _handlePointerDown.
  //   3. Re-wrap `card` in a `Listener(onPointerDown: ...)` and switch
  //      the `Transform.rotate` below back to an `AnimatedBuilder`
  //      driving the rotation off `_wiggleAngle`.
  //
  // late final AnimationController _wiggle;
  // late final Animation<double> _wiggleAngle;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _wiggle = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 320),
  //   );
  //   // ±3° wiggle that damps to zero — feels like a poke on a real post-it.
  //   _wiggleAngle = TweenSequence<double>([
  //     TweenSequenceItem(tween: Tween(begin: 0, end: 3.0), weight: 1),
  //     TweenSequenceItem(tween: Tween(begin: 3.0, end: -2.5), weight: 2),
  //     TweenSequenceItem(tween: Tween(begin: -2.5, end: 1.5), weight: 2),
  //     TweenSequenceItem(tween: Tween(begin: 1.5, end: 0), weight: 2),
  //   ]).animate(CurvedAnimation(parent: _wiggle, curve: Curves.easeInOut));
  // }
  //
  // @override
  // void dispose() {
  //   _wiggle.dispose();
  //   super.dispose();
  // }
  //
  // void _handlePointerDown(PointerDownEvent _, {required bool postIt}) {
  //   // Skip during drag (the scale-up + shadow is feedback enough) and
  //   // in classic mode (the user opted out of playful effects).
  //   if (!postIt || widget.isDragging) return;
  //   _wiggle.forward(from: 0);
  // }

  @override
  Widget build(BuildContext context) {
    final themeSettings = AppDependencies.of(context).themeSettings;
    final postIt = themeSettings.postItModeEnabled;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = postIt
        ? (colorFromHex(widget.visuals.colorHex) ?? scheme.surfaceContainerHigh)
        : scheme.surfaceContainerHigh;
    final fg = postIt && widget.visuals.colorHex != null
        ? contrastOn(bg)
        : scheme.onSurface;

    final radius = postIt ? 16.0 : 14.0;
    final shadowAlpha = widget.isDragging
        ? (isDark ? 0.85 : 0.32)
        : (isDark ? 0.55 : 0.18);
    final shadowBlur = widget.isDragging ? 24.0 : 14.0;
    final shadowDy = widget.isDragging ? 10.0 : 4.0;

    // Edit-mode chrome: a 2 px accent outline appears around the card
    // and the tile scales to 1.05 so the user can tell which block is
    // currently being edited. Drag visuals win when both are active.
    final showEditOutline = widget.isEditing && !widget.isDragging;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: showEditOutline
            ? Border.all(color: scheme.primary, width: 2)
            : null,
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
              Padding(padding: const EdgeInsets.all(12), child: widget.child),
              if (widget.topRight != null)
                Positioned(top: 4, right: 4, child: widget.topRight!),
            ],
          ),
        ),
      ),
    );

    final scale = widget.isDragging
        ? 1.03
        : (widget.isEditing ? 1.05 : 1.0);

    if (!postIt) {
      return AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: card,
      );
    }

    return Transform.translate(
      offset: Offset(
        widget.visuals.offsetX.toDouble(),
        widget.visuals.offsetY.toDouble(),
      ),
      child: Transform.rotate(
        angle: widget.visuals.rotationDeg * pi / 180,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: card,
        ),
      ),
    );
  }
}
