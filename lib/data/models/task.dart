import 'package:hive_flutter/hive_flutter.dart';
import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }

@HiveType(typeId: 0)
class Task extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String notes;
  
  @HiveField(3)
  final DateTime? dueDate;
  
  @HiveField(4)
  final TaskPriority priority;
  
  @HiveField(5)
  final List<String> tags;
  
  @HiveField(6)
  final TaskStatus status;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime updatedAt;
  
  @HiveField(9)
  final int secondsSpent;
  
  @HiveField(10)
  final bool isTimerRunning;
  
  @HiveField(11)
  final DateTime? lastTimerStarted;
  
  @HiveField(12)
  final int snoozeCount;
  
  @HiveField(13)
  final DateTime? lastSnoozed;
  
  @HiveField(14)
  final List<String> notificationOffsets;
  
  @HiveField(15)
  final int challengesCompleted;
  
  @HiveField(16)
  final int challengesFailed;
  
  @HiveField(17)
  final DateTime? lastChallengeAt;

  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    this.status = TaskStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.secondsSpent = 0,
    this.isTimerRunning = false,
    this.lastTimerStarted,
    this.snoozeCount = 0,
    this.lastSnoozed,
    this.notificationOffsets = const ['60', '30', '10'], // minutes before due
    this.challengesCompleted = 0,
    this.challengesFailed = 0,
    this.lastChallengeAt,
  });

  @override
  List<Object?> get props => [
    id, title, notes, dueDate, priority, tags, status, createdAt, updatedAt,
    secondsSpent, isTimerRunning, lastTimerStarted, snoozeCount, lastSnoozed,
    notificationOffsets, challengesCompleted, challengesFailed, lastChallengeAt,
  ];

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? dueDate,
    TaskPriority? priority,
    List<String>? tags,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? secondsSpent,
    bool? isTimerRunning,
    DateTime? lastTimerStarted,
    int? snoozeCount,
    DateTime? lastSnoozed,
    List<String>? notificationOffsets,
    int? challengesCompleted,
    int? challengesFailed,
    DateTime? lastChallengeAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      secondsSpent: secondsSpent ?? this.secondsSpent,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      lastTimerStarted: lastTimerStarted ?? this.lastTimerStarted,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozed: lastSnoozed ?? this.lastSnoozed,
      notificationOffsets: notificationOffsets ?? this.notificationOffsets,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      challengesFailed: challengesFailed ?? this.challengesFailed,
      lastChallengeAt: lastChallengeAt ?? this.lastChallengeAt,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && 
           dueDate!.month == now.month && 
           dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year && 
           dueDate!.month == tomorrow.month && 
           dueDate!.day == tomorrow.day;
  }

  bool get shouldSuggestChallenge {
    if (status == TaskStatus.completed) return false;
    
    // If overdue and not challenged in the last hour
    if (isOverdue && (lastChallengeAt == null || 
        DateTime.now().difference(lastChallengeAt!).inMinutes > 60)) {
      return true;
    }
    
    // If snoozed too many times (default 2+)
    if (snoozeCount >= 2 && (lastChallengeAt == null || 
        DateTime.now().difference(lastChallengeAt!).inMinutes > 30)) {
      return true;
    }
    
    // If in progress for too long (20+ minutes without timer activity)
    if (status == TaskStatus.inProgress && !isTimerRunning && 
        lastTimerStarted != null &&
        DateTime.now().difference(lastTimerStarted!).inMinutes > 20) {
      return true;
    }
    
    return false;
  }

  String get formattedTimeSpent {
    final hours = secondsSpent ~/ 3600;
    final minutes = (secondsSpent % 3600) ~/ 60;
    final seconds = secondsSpent % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

