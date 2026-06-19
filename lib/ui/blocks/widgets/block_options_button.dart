import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Small circular "options" button rendered in the top-right corner of a
/// filled multimedia block (photo / video / voice) when the entry is
/// editable. Opens the block's manage sheet (Replace / Remove, etc.).
///
/// Introduced by GUS-76: long-press on these blocks used to open the
/// manage sheet, which stole the gesture from `BlockGrid`'s
/// `LongPressDraggable` so a filled tile couldn't be reordered. The sheet
/// is now delegated to this explicit button, freeing long-press for drag.
///
/// Sits **inside** the block widget's content (so it scales with the
/// block via the chrome's `FittedBox`, and it works in every host — grid
/// tile and 2×2 feature block — with no per-host plumbing). A translucent
/// surface backing keeps it legible over photos / video posters.
class BlockOptionsButton extends StatelessWidget {
  const BlockOptionsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AppIcon(
            HugeIcons.strokeRoundedMoreHorizontal,
            size: 16,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
