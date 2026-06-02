import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/statistics/view_model/statistics_view_model.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/stats_empty_state.dart';

/// Vertical bars: entries per ISO week. Week start matches
/// `table_calendar`'s default Monday-start convention.
class EntryFrequencyChart extends StatelessWidget {
  const EntryFrequencyChart({super.key, required this.buckets});

  final List<WeekBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = buckets.fold<int>(0, (a, b) => a + b.count);

    return _Card(
      title: 'Entries per week',
      child: total == 0
          ? const SizedBox(
              height: 180,
              child: StatsEmptyState(
                message: 'No entries in this range',
                compact: true,
              ),
            )
          : SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxY(),
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _gridInterval(),
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: _gridInterval(),
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value % 1 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: _bottomInterval().toDouble(),
                          // Don't force-draw the first/last bucket: at
                          // wide intervals the edge labels would sit
                          // half-off the chart and clip.
                          minIncluded: false,
                          maxIncluded: false,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= buckets.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _bottomLabel(buckets[idx].weekStart),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < buckets.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: buckets[i].count.toDouble(),
                              color: scheme.primary,
                              width: _barWidth(),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  double _maxY() {
    final max = buckets.fold<int>(0, (a, b) => a > b.count ? a : b.count);
    if (max <= 7) return 7;
    return (max + 1).toDouble();
  }

  double _gridInterval() {
    final max = _maxY();
    if (max <= 7) return 1;
    if (max <= 14) return 2;
    return (max / 5).ceilToDouble();
  }

  int _bottomInterval() {
    final n = buckets.length;
    if (n <= 6) return 1;
    if (n <= 12) return 2;
    if (n <= 26) return 4;
    // Large ranges (Year ≈ 52 weeks, All): target ~5 evenly spaced
    // labels. With month-abbreviation labels (see [_bottomLabel]) this
    // reads as a timeline without crowding.
    return (n / 5).ceil();
  }

  /// Short labels for short ranges (`M/D`); month abbreviations for
  /// large ranges so the thinned-out labels stay narrow and don't
  /// overlap. (GUS-17)
  String _bottomLabel(DateTime weekStart) {
    if (buckets.length > 26) return _monthAbbr[weekStart.month - 1];
    return '${weekStart.month}/${weekStart.day}';
  }

  static const _monthAbbr = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  double _barWidth() {
    final n = buckets.length;
    if (n <= 6) return 18;
    if (n <= 12) return 12;
    if (n <= 26) return 8;
    return 4;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
