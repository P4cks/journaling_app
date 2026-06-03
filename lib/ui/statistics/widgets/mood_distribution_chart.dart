import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/stats_empty_state.dart';

/// Bar chart of how often each mood emoji appears in the selected range.
/// Bars are ordered by [moodEmojis] so the X-axis layout is stable
/// regardless of which moods the user actually picked.
class MoodDistributionChart extends StatelessWidget {
  const MoodDistributionChart({super.key, required this.distribution});

  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = distribution.values.fold<int>(0, (a, b) => a + b);

    return _Card(
      title: 'Mood distribution',
      child: total == 0
          ? const SizedBox(
              height: 180,
              child: StatsEmptyState(
                message: 'No moods logged yet',
                compact: true,
              ),
            )
          : SizedBox(
              height: 220,
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
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= moodEmojis.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                moodEmojis[idx],
                                style: const TextStyle(fontSize: 16),
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
                      for (var i = 0; i < moodEmojis.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (distribution[moodEmojis[i]] ?? 0)
                                  .toDouble(),
                              color: scheme.primary,
                              width: 14,
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
    final max = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) return 1;
    return (max + 1).toDouble();
  }

  double _gridInterval() {
    final max = _maxY();
    if (max <= 5) return 1;
    if (max <= 10) return 2;
    return (max / 5).ceilToDouble();
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
