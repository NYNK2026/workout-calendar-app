import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_record.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/body_metrics_chart.dart';
import 'record_edit_sheet.dart';
import 'month_stats_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // iOSの「ホーム画面に追加」(スタンドアロンPWA)モードでは、起動直後
    // タップ判定位置が実際の表示位置より上にズレる既知の不具合がある
    // (Flutter Issue #115829 / #111896 と同系統の現象)。
    // 記録シート(モーダルボトムシート)を1回開いて閉じると直ることが
    // 判明したため、起動直後に見えない形で同じ開閉操作を自動実行し、
    // 最初から正しいタップ判定位置になるようにする。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpViewportLayout();
    });
  }

  Future<void> _warmUpViewportLayout() async {
    if (!mounted) return;

    // showModalBottomSheetのFutureはシートが閉じるまで完了しないため、
    // ここでは待ち受けず、別タイミングで自動的に閉じる
    final sheetFuture = showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => const SizedBox.shrink(),
    );

    // 開いた直後、少し待ってから自動的に閉じる
    await Future.delayed(const Duration(milliseconds: 150));
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // 念のためシートのFutureも待機(エラーは無視)
    unawaited(sheetFuture.catchError((_) {}));

    // 1回だけでは直らない場合に備え、少し間を置いてもう一度実行する
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final secondSheetFuture = showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => const SizedBox.shrink(),
    );
    await Future.delayed(const Duration(milliseconds: 150));
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    unawaited(secondSheetFuture.catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (!provider.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.mint)),
      );
    }

    final selectedRecord = provider.getRecord(_selectedDay);
    final streak = provider.getCurrentStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('宅トレカレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MonthStatsScreen(month: _focusedDay),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (streak > 0) _buildStreakBanner(streak),
            const BodyMetricsChart(),
            _buildCalendarCard(provider),
            const SizedBox(height: 16),
            _buildSelectedDaySection(selectedRecord),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mint,
        onPressed: () => RecordEditSheet.show(context, _selectedDay),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStreakBanner(int streak) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.mint, size: 20),
          const SizedBox(width: 8),
          Text(
            '$streak日連続で記録中!このまま続けよう',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(WorkoutProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: TableCalendar<WorkoutRecord>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        locale: 'ja_JP',
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          weekendStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.mintLight,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          selectedDecoration: BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          defaultTextStyle: TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: TextStyle(color: AppColors.textPrimary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            final record = provider.getRecord(day);
            if (record == null || !record.hasRecord) return null;
            return Positioned(
              bottom: 4,
              child: _buildDotsForRecord(record),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDotsForRecord(WorkoutRecord record) {
    final dots = <Widget>[];
    if (record.cardioMinutes > 0) {
      dots.add(_dot(AppColors.cardio));
    }
    if (record.strengthMinutes > 0) {
      dots.add(_dot(AppColors.strength));
    }
    if (record.otherMinutes > 0) {
      dots.add(_dot(AppColors.other));
    }
    if (dots.isEmpty && record.memo.trim().isNotEmpty) {
      dots.add(_dot(AppColors.textSecondary));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: dots);
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSelectedDaySection(WorkoutRecord? record) {
    final dateLabel = DateFormat('M月d日 (E)', 'ja_JP').format(_selectedDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => RecordEditSheet.show(context, _selectedDay),
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppColors.mint),
                    SizedBox(width: 4),
                    Text(
                      '編集',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (record == null || !record.hasRecord)
            _buildEmptyState()
          else
            _buildRecordDetail(record),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Text(
            'この日の記録はまだありません',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordDetail(WorkoutRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _statItem('有酸素', record.cardioMinutes, AppColors.cardio, Icons.directions_run),
            ),
            Expanded(
              child: _statItem('筋トレ', record.strengthMinutes, AppColors.strength, Icons.fitness_center),
            ),
            Expanded(
              child: _statItem('その他', record.otherMinutes, AppColors.other, Icons.sports_gymnastics),
            ),
          ],
        ),
        if (record.weightKg != null || record.bodyFatPercent != null) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              if (record.weightKg != null)
                Expanded(
                  child: _bodyMetricItem(
                    '体重',
                    '${_fmtNum(record.weightKg!)}kg',
                    AppColors.weight,
                    Icons.monitor_weight_outlined,
                  ),
                ),
              if (record.bodyFatPercent != null)
                Expanded(
                  child: _bodyMetricItem(
                    '体脂肪率',
                    '${_fmtNum(record.bodyFatPercent!)}%',
                    AppColors.bodyFat,
                    Icons.percent,
                  ),
                ),
            ],
          ),
        ],
        if (record.memo.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text(
            'メモ',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            record.memo,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _statItem(String label, int minutes, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          '$minutes分',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _bodyMetricItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  String _fmtNum(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
