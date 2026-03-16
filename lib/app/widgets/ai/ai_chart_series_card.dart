import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';

class AiChartSeriesCard extends StatelessWidget {
  const AiChartSeriesCard({super.key, required this.points});

  final List<AiChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final metric = points.first.metric;
    final maxY = points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1, double.infinity);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart Preview: $metric',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = points[idx].label;
                        final short = label.length > 10
                            ? '${label.substring(0, 10)}...'
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: theme.textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
