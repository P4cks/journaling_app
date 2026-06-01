import 'dart:math';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_render_context.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';

/// The natural content size used by every block body — roughly a 1×1
/// grid cell minus the chrome's 12 px padding. The chrome lays content
/// out at this size and uses a `FittedBox` to blow it up to fit
/// whatever box it ends up in (a ~160 px grid tile, a ~330 px expanded
/// card, or an intermediate size during a Hero flight). Layout stays
/// predictable — TextField wrap, carousel item positions etc. never
/// reflow as the box morphs.
const double kBlockContentReferenceSize = 136.0;

/// The natural chrome size — content reference + 12 px padding on each
/// side. This is the "logical" size the FittedBox lays out at before
/// scaling to fit the available constraints.
const double kBlockChromeReferenceSize = kBlockContentReferenceSize + 24.0;

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
/// **Padding is owned by each block widget, not by the chrome.** The
/// 12 px inset between the rounded-card edge and the block's content
/// is added by each block widget INSIDE its own outermost gesture
/// wrapper (e.g. `DelayedTapFocus`, the carousel scaffold's
/// `GestureDetector`). Putting the padding in the chrome made the
/// inset a gesture dead-zone — taps in the 12 px ring fell up to the
/// body's tap-to-unfocus handler, causing a "tapping inconsistent"
/// regression and (when combined with a previous `unfocus()` on page
/// change) a keyboard-flash after entry switch. Block widgets now own
/// their padding; the chrome stays pure-theming.
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

    // The body is always laid out at the natural reference size and
    // scaled to fit the available constraints via `FittedBox` wrapped
    // in `SizedBox.expand`. The `SizedBox.expand` is the key — without
    // it the Stack's default `StackFit.loose` gives the FittedBox
    // loose constraints, so the FittedBox sizes to its child's
    // intrinsic 160 px and refuses to grow. With it, the FittedBox
    // fills the chrome's full constraints, then scales its 160 px
    // child to match: visually a no-op in the grid (~160 px tile),
    // a uniform ~2× scale in the expanded host (~330 px), and a
    // smooth interpolation at every intermediate Hero flight rect.
    //
    // Padding lives **inside** each block widget now (not in the
    // chrome) so taps in the visual 12 px inset still reach the
    // block's own gesture wrapper. The chrome stays pure-theming.
    final inner = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: kBlockChromeReferenceSize,
          height: kBlockChromeReferenceSize,
          child: child,
        ),
      ),
    );

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
              inner,
              if (topRight != null)
                Positioned(top: 4, right: 4, child: topRight!),
            ],
          ),
        ),
      ),
    );

    final scale = isDragging ? 1.03 : (showEditOutline ? 1.05 : 1.0);

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
      offset: Offset(visuals.offsetX.toDouble(), visuals.offsetY.toDouble()),
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
