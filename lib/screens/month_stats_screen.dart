import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

class MonthStatsScreen extends StatelessWidget {
  final DateTime month;

  const MonthStatsScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final stats = provider.getMonthStats(month);
    final monthLabel = DateFormat('yyyy年M月', 'ja_JP').format(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final avgPerDay = stats.workoutDays > 0
        ? (stats.totalMinutes / stats.workoutDays).round()
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text('$monthLabel の統計')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(stats, daysInMonth, avgPerDay),
            const SizedBox(height: 16),
            _buildBreakdownCard(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MonthStats stats, int daysInMonth, int avgPerDay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.mint),
              const SizedBox(width: 8),
              Text(
                '記録日数 ${stats.workoutDays} / $daysInMonth 日',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _bigStat('合計時間', '${stats.totalMinutes}分'),
              ),
              Expanded(
                child: _bigStat('1日平均', '$avgPerDay分'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildBreakdownCard(MonthStats stats) {
    final total = stats.totalMinutes == 0 ? 1 : stats.totalMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '種類別の内訳',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _breakdownRow('有酸素運動', stats.totalCardioMinutes, total, AppColors.cardio, Icons.directions_run),
          const SizedBox(height: 14),
          _breakdownRow('筋トレ', stats.totalStrengthMinutes, total, AppColors.strength, Icons.fitness_center),
          const SizedBox(height: 14),
          _breakdownRow('その他', stats.totalOtherMinutes, total, AppColors.other, Icons.sports_gymnastics),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int minutes, int total, Color color, IconData icon) {
    final ratio = minutes / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            const Spacer(),
            Text('$minutes分', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
