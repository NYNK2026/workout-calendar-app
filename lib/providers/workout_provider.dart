import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/workout_record.dart';

/// 日付を "yyyy-MM-dd" 形式のキーに変換
String dateToKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month, date.day));
}

class WorkoutProvider extends ChangeNotifier {
  static const String boxName = 'workout_records';
  late Box<WorkoutRecord> _box;
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> init() async {
    _box = await Hive.openBox<WorkoutRecord>(boxName);
    _isReady = true;
    notifyListeners();
  }

  /// 指定日の記録を取得(なければnull)
  WorkoutRecord? getRecord(DateTime date) {
    final key = dateToKey(date);
    return _box.get(key);
  }

  /// 指定日の記録を保存(新規作成または更新)
  Future<void> saveRecord({
    required DateTime date,
    required int cardioMinutes,
    required int strengthMinutes,
    required int otherMinutes,
    required String memo,
    double? weightKg,
    double? bodyFatPercent,
  }) async {
    final key = dateToKey(date);
    final record = WorkoutRecord(
      dateKey: key,
      cardioMinutes: cardioMinutes,
      strengthMinutes: strengthMinutes,
      otherMinutes: otherMinutes,
      memo: memo,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
    );

    if (!record.hasRecord) {
      // 全部空なら削除(不要なレコードを溜めない)
      await _box.delete(key);
    } else {
      await _box.put(key, record);
    }
    notifyListeners();
  }

  /// 指定日の記録を削除
  Future<void> deleteRecord(DateTime date) async {
    final key = dateToKey(date);
    await _box.delete(key);
    notifyListeners();
  }

  /// 指定月の全記録を取得(key: 日付キー)
  Map<String, WorkoutRecord> getRecordsForMonth(DateTime month) {
    final result = <String, WorkoutRecord>{};
    final prefix = DateFormat('yyyy-MM').format(DateTime(month.year, month.month));
    for (final key in _box.keys) {
      if (key.toString().startsWith(prefix)) {
        final record = _box.get(key);
        if (record != null) {
          result[key.toString()] = record;
        }
      }
    }
    return result;
  }

  /// 指定月の統計情報を取得
  MonthStats getMonthStats(DateTime month) {
    final records = getRecordsForMonth(month);
    int totalCardio = 0;
    int totalStrength = 0;
    int totalOther = 0;
    int workoutDays = 0;

    for (final record in records.values) {
      totalCardio += record.cardioMinutes;
      totalStrength += record.strengthMinutes;
      totalOther += record.otherMinutes;
      if (record.hasRecord) workoutDays++;
    }

    return MonthStats(
      totalCardioMinutes: totalCardio,
      totalStrengthMinutes: totalStrength,
      totalOtherMinutes: totalOther,
      workoutDays: workoutDays,
    );
  }

  /// 連続記録日数(今日から遡って)を計算
  int getCurrentStreak() {
    int streak = 0;
    DateTime cursor = DateTime.now();
    while (true) {
      final record = getRecord(cursor);
      if (record != null && record.hasRecord) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// 直近N日間の体重・体脂肪率の記録を日付昇順で取得(グラフ表示用)
  /// 記録がない日はスキップされる(データがある点のみ繋ぐ)
  List<BodyMetricPoint> getRecentBodyMetrics({int days = 30}) {
    final result = <BodyMetricPoint>[];
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final record = getRecord(date);
      if (record != null &&
          (record.weightKg != null || record.bodyFatPercent != null)) {
        result.add(
          BodyMetricPoint(
            date: date,
            weightKg: record.weightKg,
            bodyFatPercent: record.bodyFatPercent,
          ),
        );
      }
    }
    return result;
  }

  /// 直近の体重記録(最新)を取得
  double? getLatestWeight() {
    for (int i = 0; i < 365; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final record = getRecord(date);
      if (record?.weightKg != null) return record!.weightKg;
    }
    return null;
  }

  /// 直近の体脂肪率記録(最新)を取得
  double? getLatestBodyFat() {
    for (int i = 0; i < 365; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final record = getRecord(date);
      if (record?.bodyFatPercent != null) return record!.bodyFatPercent;
    }
    return null;
  }
}

/// 体重・体脂肪率のグラフ表示用データポイント
class BodyMetricPoint {
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPercent;

  BodyMetricPoint({
    required this.date,
    this.weightKg,
    this.bodyFatPercent,
  });
}

class MonthStats {
  final int totalCardioMinutes;
  final int totalStrengthMinutes;
  final int totalOtherMinutes;
  final int workoutDays;

  MonthStats({
    required this.totalCardioMinutes,
    required this.totalStrengthMinutes,
    required this.totalOtherMinutes,
    required this.workoutDays,
  });

  int get totalMinutes => totalCardioMinutes + totalStrengthMinutes + totalOtherMinutes;
}
