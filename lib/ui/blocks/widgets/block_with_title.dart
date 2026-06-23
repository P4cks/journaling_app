import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/theme/tonal.dart';

/// Wraps a block body with an optional title row above it.
///
/// When [title] is null or empty the body is returned unchanged — same
/// layout as a block without titles. Otherwise a compact `labelSmall`
/// title is rendered at the top of the block's square area and the body
/// takes the remaining space via `Expanded`.
///
/// Used by mood / weather carousels (and future custom-carousel blocks)
/// to surface their per-type-global title from
/// [BlockSettings](../../../data/services/block_settings.dart).
class BlockWithTitle extends StatelessWidget {
  const BlockWithTitle({super.key, required this.title, required this.body});

  final String? title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final t = title;
    if (t == null || t.isEmpty) return body;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Text(
            t,
            textAlign: TextAlign.center,
            // Muted tonal ink so the title stays on-hue on a coloured block
            // (was onSurfaceVariant, a fixed theme grey — GUS-86).
            style: theme.textTheme.labelSmall?.copyWith(
              color: blockInk(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
