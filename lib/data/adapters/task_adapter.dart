import 'package:hive_flutter/hive_flutter.dart';
import 'package:vanguard/data/models/task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Task(
      id: fields[0] ?? '',
      title: fields[1] ?? '',
      notes: fields[2] ?? '',
      dueDate: fields[3],
      priority: TaskPriority.values[fields[4] ?? 1],
      tags: (fields[5] as List?)?.cast<String>() ?? [],
      status: TaskStatus.values[fields[6] ?? 0],
      createdAt: fields[7] ?? DateTime.now(),
      updatedAt: fields[8] ?? DateTime.now(),
      secondsSpent: fields[9] ?? 0,
      isTimerRunning: fields[10] ?? false,
      lastTimerStarted: fields[11],
      snoozeCount: fields[12] ?? 0,
      lastSnoozed: fields[13],
      notificationOffsets: (fields[14] as List?)?.cast<String>() ?? ['60', '30', '10'],
      challengesCompleted: fields[15] ?? 0,
      challengesFailed: fields[16] ?? 0,
      lastChallengeAt: fields[17],
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.priority.index)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.status.index)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.secondsSpent)
      ..writeByte(10)
      ..write(obj.isTimerRunning)
      ..writeByte(11)
      ..write(obj.lastTimerStarted)
      ..writeByte(12)
      ..write(obj.snoozeCount)
      ..writeByte(13)
      ..write(obj.lastSnoozed)
      ..writeByte(14)
      ..write(obj.notificationOffsets)
      ..writeByte(15)
      ..write(obj.challengesCompleted)
      ..writeByte(16)
      ..write(obj.challengesFailed)
      ..writeByte(17)
      ..write(obj.lastChallengeAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}