import 'package:flutter/material.dart';

class BlockCard extends StatelessWidget {
  const BlockCard({super.key, required this.child, this.topRight});

  final Widget child;
  final Widget? topRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.card,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
          if (topRight != null)
            Positioned(top: 4, right: 4, child: topRight!),
        ],
      ),
    );
  }
}
