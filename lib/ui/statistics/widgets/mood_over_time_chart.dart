import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/statistics/view_model/statistics_view_model.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/stats_empty_state.dart';

/// Line chart of mood score (0–5) over time. Days with no mood emit
/// `null` from the view-model and break the line into segments.
class MoodOverTimeChart extends StatelessWidget {
  const MoodOverTimeChart({super.key, required this.points});

  final List<MoodPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final segments = _segmentize(points);
    final hasData = segments.any((s) => s.isNotEmpty);

    return _Card(
      title: 'Mood over time',
      child: !hasData
          ? const SizedBox(
              height: 180,
              child: StatsEmptyState(
                message: 'No mood data in this range',
                compact: true,
              ),
            )
          : SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1)
                        .clamp(1, double.maxFinite)
                        .toDouble(),
                    minY: 0,
                    maxY: 5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
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
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) {
                              return const SizedBox.shrink();
                            }
                            final d = points[idx].day;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${d.month}/${d.day}',
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
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      for (final segment in segments)
                        if (segment.isNotEmpty)
                          LineChartBarData(
                            spots: segment,
                            isCurved: true,
                            curveSmoothness: 0.2,
                            color: scheme.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, _, _) =>
                                  FlDotCirclePainter(
                                    radius: 3,
                                    color: scheme.primary,
                                    strokeWidth: 0,
                                  ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Split the points list into contiguous non-null segments. Each
  /// segment becomes a separate `LineChartBarData` so the line breaks
  /// across null days.
  List<List<FlSpot>> _segmentize(List<MoodPoint> pts) {
    final segments = <List<FlSpot>>[];
    var current = <FlSpot>[];
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      if (p.score == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = <FlSpot>[];
        }
        continue;
      }
      current.add(FlSpot(i.toDouble(), p.score!));
    }
    if (current.isNotEmpty) segments.add(current);
    return segments;
  }

  int _bottomInterval() {
    final n = points.length;
    if (n <= 7) return 1;
    if (n <= 14) return 2;
    if (n <= 31) return 5;
    if (n <= 90) return 14;
    if (n <= 180) return 30;
    return (n / 6).ceil();
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
