import 'package:flutter/material.dart';

class BlockCard extends StatelessWidget {
  const BlockCard({super.key, required this.child, this.topRight});

  final Widget child;
  final Widget? topRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.55 : 0.18),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: child),
          if (topRight != null) Positioned(top: 4, right: 4, child: topRight!),
        ],
      ),
    );
  }
}
