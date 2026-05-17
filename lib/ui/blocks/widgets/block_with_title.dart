import 'package:flutter/material.dart';

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
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
