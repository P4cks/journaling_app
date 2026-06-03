import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/statistics/view_model/statistics_view_model.dart';

/// Range picker for the statistics page. Replaces the former
/// `SegmentedButton` switcher with a dropdown.
///
/// Free users may pick `Week` and `Month`; `Year` and `All` are
/// Pro-locked ([StatRangeDisplay.isProOnly]) — their menu items carry a
/// [ProLockBadge] and tapping one presents the paywall via [requirePro].
/// The range only changes on an already-Pro user or a successful
/// purchase; cancelling the paywall leaves the current selection intact.
class StatRangeSelector extends StatelessWidget {
  const StatRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.subscriptions,
  });

  final StatRange value;
  final ValueChanged<StatRange> onChanged;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPro = subscriptions.isPro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          // Fixed width + isExpanded so the dropdown menu is wide enough
          // for the "Year"/"All" + Pro-badge rows. DropdownButton forces
          // the menu to the button's width, so a content-sized button
          // (just the bare label) clipped the badge in free mode (GUS-38).
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StatRange>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              onChanged: (selected) => _onSelected(context, selected),
              // Button face always shows the bare label (never a badge —
              // a free user can only ever have a free range selected).
              selectedItemBuilder: (context) => [
                for (final r in StatRange.values)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(r.label),
                  ),
              ],
              items: [
                for (final r in StatRange.values)
                  DropdownMenuItem<StatRange>(
                    value: r,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(r.label, overflow: TextOverflow.ellipsis),
                        ),
                        if (r.isProOnly && !isPro) ...[
                          const SizedBox(width: 8),
                          const ProLockBadge(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, StatRange? selected) async {
    if (selected == null || selected == value) return;
    if (selected.isProOnly && !subscriptions.isPro) {
      final ok = await requirePro(subscriptions, context: context);
      if (!ok) return;
    }
    onChanged(selected);
  }
}
