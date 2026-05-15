import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/statistics/view_model/statistics_view_model.dart';

class StatRangeSelector extends StatelessWidget {
  const StatRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StatRange value;
  final ValueChanged<StatRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<StatRange>(
        segments: [
          for (final r in StatRange.values)
            ButtonSegment(value: r, label: Text(r.label)),
        ],
        selected: {value},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
      ),
    );
  }
}
