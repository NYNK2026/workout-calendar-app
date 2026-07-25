import 'package:hive/hive.dart';

part 'workout_record.g.dart';

/// 1日分の宅トレ記録データモデル
@HiveType(typeId: 0)
class WorkoutRecord extends HiveObject {
  /// 日付キー "yyyy-MM-dd" 形式
  @HiveField(0)
  String dateKey;

  /// 有酸素運動(分)
  @HiveField(1)
  int cardioMinutes;

  /// 筋トレ(分)
  @HiveField(2)
  int strengthMinutes;

  /// その他運動(分)
  @HiveField(3)
  int otherMinutes;

  /// メモ
  @HiveField(4)
  String memo;

  /// 体重(kg) 未記録の場合はnull
  @HiveField(5)
  double? weightKg;

  /// 体脂肪率(%) 未記録の場合はnull
  @HiveField(6)
  double? bodyFatPercent;

  WorkoutRecord({
    required this.dateKey,
    this.cardioMinutes = 0,
    this.strengthMinutes = 0,
    this.otherMinutes = 0,
    this.memo = '',
    this.weightKg,
    this.bodyFatPercent,
  });

  /// 合計運動時間(分)
  int get totalMinutes => cardioMinutes + strengthMinutes + otherMinutes;

  /// 何かしらの記録があるかどうか
  bool get hasRecord =>
      cardioMinutes > 0 ||
      strengthMinutes > 0 ||
      otherMinutes > 0 ||
      memo.trim().isNotEmpty ||
      weightKg != null ||
      bodyFatPercent != null;

  WorkoutRecord copyWith({
    int? cardioMinutes,
    int? strengthMinutes,
    int? otherMinutes,
    String? memo,
    double? weightKg,
    double? bodyFatPercent,
  }) {
    return WorkoutRecord(
      dateKey: dateKey,
      cardioMinutes: cardioMinutes ?? this.cardioMinutes,
      strengthMinutes: strengthMinutes ?? this.strengthMinutes,
      otherMinutes: otherMinutes ?? this.otherMinutes,
      memo: memo ?? this.memo,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
    );
  }
}
