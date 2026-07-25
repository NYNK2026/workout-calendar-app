import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

/// トップ画面に常時表示する体重・体脂肪率の推移グラフ
class BodyMetricsChart extends StatelessWidget {
  const BodyMetricsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final points = provider.getRecentBodyMetrics(days: 30);
    final latestWeight = provider.getLatestWeight();
    final latestBodyFat = provider.getLatestBodyFat();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart, size: 18, color: AppColors.weight),
                  SizedBox(width: 6),
                  Text(
                    '体重・体脂肪率の推移(直近30日)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendChip('体重', AppColors.weight, latestWeight, 'kg'),
              const SizedBox(width: 12),
              _legendChip('体脂肪率', AppColors.bodyFat, latestBodyFat, '%'),
            ],
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            _buildEmptyState()
          else
            SizedBox(
              height: 160,
              child: _buildChart(points),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _legendChip(String label, Color color, double? value, String unit) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          value != null ? '$label ${_fmt(value)}$unit' : '$label 未記録',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '体重・体脂肪率を記録するとここにグラフが表示されます',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildChart(List<BodyMetricPoint> points) {
    final weightSpots = <FlSpot>[];
    final bodyFatSpots = <FlSpot>[];

    double minWeight = double.infinity;
    double maxWeight = -double.infinity;
    double minFat = double.infinity;
    double maxFat = -double.infinity;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.weightKg != null) {
        weightSpots.add(FlSpot(i.toDouble(), p.weightKg!));
        if (p.weightKg! < minWeight) minWeight = p.weightKg!;
        if (p.weightKg! > maxWeight) maxWeight = p.weightKg!;
      }
      if (p.bodyFatPercent != null) {
        bodyFatSpots.add(FlSpot(i.toDouble(), p.bodyFatPercent!));
        if (p.bodyFatPercent! < minFat) minFat = p.bodyFatPercent!;
        if (p.bodyFatPercent! > maxFat) maxFat = p.bodyFatPercent!;
      }
    }

    // 体重と体脂肪率はスケールが違うため、それぞれ0-1に正規化してから
    // 表示用に体重スケールへ再マッピングする(2軸っぽい見た目にする)
    final hasWeight = weightSpots.isNotEmpty;
    final hasFat = bodyFatSpots.isNotEmpty;

    double weightPadding = hasWeight ? (maxWeight - minWeight).abs() * 0.15 : 1;
    if (weightPadding < 0.5) weightPadding = 0.5;
    final chartMinY = hasWeight ? minWeight - weightPadding : 0.0;
    final chartMaxY = hasWeight ? maxWeight + weightPadding : 100.0;

    // 体脂肪率を体重グラフのY軸スケールに正規化してマッピング
    List<FlSpot> normalizedFatSpots = [];
    if (hasFat) {
      final fatRange = (maxFat - minFat).abs() < 0.001 ? 1.0 : (maxFat - minFat);
      normalizedFatSpots = bodyFatSpots.map((spot) {
        final ratio = (spot.y - minFat) / fatRange;
        final mappedY = chartMinY + ratio * (chartMaxY - chartMinY);
        return FlSpot(spot.x, mappedY);
      }).toList();
    }

    return LineChart(
      LineChartData(
        minY: chartMinY,
        maxY: chartMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (chartMaxY - chartMinY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: (chartMaxY - chartMinY) / 4 == 0 ? 1 : (chartMaxY - chartMinY) / 4,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: (points.length / 4).clamp(1, 30).roundToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                final date = points[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round();
                if (idx < 0 || idx >= points.length) return null;
                final p = points[idx];
                final isFatLine = spot.barIndex == 1;
                if (isFatLine) {
                  return LineTooltipItem(
                    p.bodyFatPercent != null ? '体脂肪率 ${_fmt(p.bodyFatPercent!)}%' : '',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }
                return LineTooltipItem(
                  p.weightKg != null ? '体重 ${_fmt(p.weightKg!)}kg' : '',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          if (hasWeight)
            LineChartBarData(
              spots: weightSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.weight,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.weight,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.weight.withValues(alpha: 0.08),
              ),
            ),
          if (hasFat)
            LineChartBarData(
              spots: normalizedFatSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.bodyFat,
              barWidth: 2.5,
              dashArray: [6, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.bodyFat,
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
