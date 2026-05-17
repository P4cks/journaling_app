import 'package:flutter/material.dart';

/// Empty-state alternative to the centred em-dash placeholder used by
/// carousel blocks (mood, manual weather, custom carousel). Renders
/// every option in a horizontal row at the same dimmed style the
/// expanded carousel uses for non-focused items, so the user sees
/// all choices at a glance and can tap one directly without first
/// expanding a tap-to-show carousel.
///
/// Items shrink to fit the tile via `FittedBox` so even a long item
/// list (custom carousels can have many items) renders without
/// overflowing the 1×1 block. Each cell wraps `[itemBuilder]`'s
/// output in a tap target that calls `[onPick]`.
///
/// Used only in `BlockMode.editable` + null-selection. In
/// `BlockMode.readOnly` the carousels keep the em-dash placeholder
/// because there's nothing to tap.
class CarouselPickRow<T> extends StatelessWidget {
  const CarouselPickRow({
    super.key,
    required this.options,
    required this.itemBuilder,
    required this.onPick,
  });

  final List<T> options;

  /// Build one option, rendered at its non-focused style (small +
  /// dimmed). The same builder a carousel uses for `isSelected:
  /// false` items.
  final Widget Function(BuildContext context, T option) itemBuilder;

  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final option in options)
            Expanded(
              child: InkWell(
                onTap: () => onPick(option),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: itemBuilder(context, option),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
