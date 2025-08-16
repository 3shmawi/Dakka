import 'package:hive_flutter/hive_flutter.dart';
import 'package:vanguard/data/models/challenge.dart';

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 3;

  @override
  Challenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Challenge(
      id: fields[0] ?? '',
      taskId: fields[1] ?? '',
      type: ChallengeType.values[fields[2] ?? 0],
      title: fields[3] ?? '',
      description: fields[4] ?? '',
      durationMinutes: fields[5] ?? 10,
      status: ChallengeStatus.values[fields[6] ?? 0],
      createdAt: fields[7] ?? DateTime.now(),
      startedAt: fields[8],
      completedAt: fields[9],
      reward: fields[10],
      penalty: fields[11],
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.durationMinutes)
      ..writeByte(6)
      ..write(obj.status.index)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.startedAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.reward)
      ..writeByte(11)
      ..write(obj.penalty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
