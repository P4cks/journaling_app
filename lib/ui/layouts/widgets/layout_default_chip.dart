import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Compact "Default" pill marking the user's default layout. Shared by
/// the layouts list (`LayoutsScreen`) and the "Choose layout" picker
/// sheet so the default reads the same in both places (GUS-28).
class LayoutDefaultChip extends StatelessWidget {
  const LayoutDefaultChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
            color: scheme.onPrimaryContainer,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Default',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
