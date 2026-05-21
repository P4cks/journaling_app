import 'dart:math';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_render_context.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';

/// The natural content size used by every block body in the grid —
/// roughly a 1×1 cell minus the chrome's 12 px padding. The expanded
/// chrome lays content out at this size and uses `Transform.scale`
/// to blow it up to fit the larger box (see the LayoutBuilder block
/// in [BlockChrome.build]). Layout stays predictable; only the
/// visual scale changes per Hero flight frame.
const double kBlockContentReferenceSize = 136.0;

/// The visual chrome wrapping every block — replaces the old
/// `PostItBlock`.
///
/// **Pure theming.** Reads `themeSettings.postItModeEnabled` to switch
/// between post-it visuals (rotation, offset, palette colour) and
/// classic flat-card visuals. Does **not** gate any animation,
/// gesture, or interaction logic on the post-it flag — that's the
/// whole point of the rewrite. Flipping the flag in settings updates
/// every chrome instantly via the root `ListenableBuilder(listenable:
/// themeSettings)` in `MyApp.build`.
///
/// **Outline rule.** The 2 px accent outline appears only when
/// `host == BlockHostKind.grid && isEditing` (in-place edit mode). The
/// expanded route already conveys "this is the active editor" via the
/// blurred backdrop, so an outline there would be redundant — and
/// today's outline in the route was a bug.
///
/// **Drag scale.** When `isDragging` is true the card scales to 1.03
/// and the shadow grows; this is independent of `isEditing`. When both
/// are true, drag wins (drag scale 1.03 > edit scale 1.05? actually
/// drag is the louder feedback — the user is actively manipulating).
///
/// **Layout invariant.** All transforms are visual only — the
/// underlying `RenderBox` stays axis-aligned, so the drag/insertion
/// math in `BlockGrid` is unaffected.
///
/// Wiggle scaffolding from the previous PR was removed in this
/// rewrite. If we want it back later, it's preserved in PR #25's
/// `post_it_block.dart` (search the file history).
class BlockChrome extends StatelessWidget {
  const BlockChrome({
    super.key,
    required this.child,
    this.visuals = BlockVisuals.zero,
    this.host = BlockHostKind.grid,
    this.isEditing = false,
    this.isDragging = false,
    this.topRight,
  });

  /// Body content (a block-type-specific widget).
  final Widget child;

  /// Persisted visuals (rotation, offset, palette colour) — used only
  /// when post-it mode is enabled.
  final BlockVisuals visuals;

  /// Where the chrome is being rendered. Drives the outline rule.
  final BlockHostKind host;

  /// True when this block is the active in-place editing target.
  /// Adds a subtle scale + a 2 px accent outline (grid host only).
  final bool isEditing;

  /// True while this tile is being dragged for reorder. Scales the
  /// card up slightly and grows the shadow.
  final bool isDragging;

  /// Optional top-right affordance — used by the layout editor for a
  /// delete icon on each tile.
  final Widget? topRight;

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

    // Outline rule: grid-host only. The expanded route's blur + Hero
    // is its own affordance.
    final showEditOutline =
        isEditing && !isDragging && host == BlockHostKind.grid;

    // In the expanded host the inner content scales proportionally
    // with the chrome — that's what makes the Hero "feel" like a
    // zoom (emoji enlarges, text font grows, etc.) instead of a
    // small grid tile rattling around in a big card. The reference
    // size matches the typical grid content area (160 px cell minus
    // the 12 px chrome padding ≈ 136 px). `LayoutBuilder` re-runs on
    // every Hero flight frame so the scale tracks the chrome's
    // current width smoothly. We pin the inner layout at
    // `kBlockContentReferenceSize` and let `Transform.scale` blow it
    // up visually — that way TextField wrapping / carousel layout
    // stays predictable instead of reflowing per frame.
    Widget inner = child;
    if (host == BlockHostKind.expanded) {
      inner = LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : kBlockContentReferenceSize;
          final scale = (available / kBlockContentReferenceSize)
              .clamp(1.0, 6.0);
          return Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: kBlockContentReferenceSize,
              height: kBlockContentReferenceSize,
              child: child,
            ),
          );
        },
      );
    }

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
              Padding(padding: const EdgeInsets.all(12), child: inner),
              if (topRight != null)
                Positioned(top: 4, right: 4, child: topRight!),
            ],
          ),
        ),
      ),
    );

    final scale = isDragging
        ? 1.03
        : (showEditOutline ? 1.05 : 1.0);

    // Classic mode: only the scale + card. No rotation, no offset.
    if (!postIt) {
      return AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: card,
      );
    }

    // Post-it mode: rotation + offset wrap the scaled card.
    return Transform.translate(
      offset: Offset(
        visuals.offsetX.toDouble(),
        visuals.offsetY.toDouble(),
      ),
      child: Transform.rotate(
        angle: visuals.rotationDeg * pi / 180,
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
