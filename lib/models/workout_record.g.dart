// Manually written Hive TypeAdapter (build_runner不使用)
part of 'workout_record.dart';

class WorkoutRecordAdapter extends TypeAdapter<WorkoutRecord> {
  @override
  final int typeId = 0;

  @override
  WorkoutRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutRecord(
      dateKey: fields[0] as String,
      cardioMinutes: (fields[1] as int?) ?? 0,
      strengthMinutes: (fields[2] as int?) ?? 0,
      otherMinutes: (fields[3] as int?) ?? 0,
      memo: (fields[4] as String?) ?? '',
      weightKg: (fields[5] as num?)?.toDouble(),
      bodyFatPercent: (fields[6] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.cardioMinutes)
      ..writeByte(2)
      ..write(obj.strengthMinutes)
      ..writeByte(3)
      ..write(obj.otherMinutes)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.weightKg)
      ..writeByte(6)
      ..write(obj.bodyFatPercent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
