import 'package:hive_flutter/hive_flutter.dart';
import 'package:equatable/equatable.dart';

enum ChallengeType {
  sprint,        // Quick 10-minute bursts
  focus,         // No distractions challenge
  breakdown,     // Break into smaller pieces
  penalty,       // Penalty if failed
  reward,        // Reward if completed
  timeAttack     // Race against time
}

enum ChallengeStatus {
  suggested,
  active,
  completed,
  failed,
  skipped
}

@HiveType(typeId: 3)
class Challenge extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String taskId;
  
  @HiveField(2)
  final ChallengeType type;
  
  @HiveField(3)
  final String title;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final int durationMinutes;
  
  @HiveField(6)
  final ChallengeStatus status;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime? startedAt;
  
  @HiveField(9)
  final DateTime? completedAt;
  
  @HiveField(10)
  final String? reward;
  
  @HiveField(11)
  final String? penalty;

  const Challenge({
    required this.id,
    required this.taskId,
    required this.type,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.status = ChallengeStatus.suggested,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.reward,
    this.penalty,
  });

  @override
  List<Object?> get props => [
    id, taskId, type, title, description, durationMinutes, status,
    createdAt, startedAt, completedAt, reward, penalty,
  ];

  Challenge copyWith({
    String? id,
    String? taskId,
    ChallengeType? type,
    String? title,
    String? description,
    int? durationMinutes,
    ChallengeStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? reward,
    String? penalty,
  }) {
    return Challenge(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      reward: reward ?? this.reward,
      penalty: penalty ?? this.penalty,
    );
  }

  int? get remainingMinutes {
    if (startedAt == null || status != ChallengeStatus.active) return null;
    final elapsed = DateTime.now().difference(startedAt!).inMinutes;
    final remaining = durationMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  double get progressPercentage {
    if (startedAt == null || status != ChallengeStatus.active) return 0.0;
    final elapsed = DateTime.now().difference(startedAt!).inMinutes;
    return (elapsed / durationMinutes).clamp(0.0, 1.0);
  }

  String get emoji {
    switch (type) {
      case ChallengeType.sprint:
        return '⚡';
      case ChallengeType.focus:
        return '🎯';
      case ChallengeType.breakdown:
        return '🧩';
      case ChallengeType.penalty:
        return '⚠️';
      case ChallengeType.reward:
        return '🎁';
      case ChallengeType.timeAttack:
        return '⏱️';
    }
  }

  static List<Challenge> generateChallenges(String taskId, String taskTitle, {
    required bool isOverdue,
    required int snoozeCount,
    required bool isHighPriority,
    required int estimatedMinutes,
  }) {
    final challenges = <Challenge>[];
    final now = DateTime.now();

    // Sprint Challenge
    challenges.add(Challenge(
      id: 'sprint_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      type: ChallengeType.sprint,
      title: 'Sprint 10m',
      description: 'Start a 10-minute countdown. Complete the smallest piece now.',
      durationMinutes: 10,
      createdAt: now,
    ));

    // Focus Challenge
    challenges.add(Challenge(
      id: 'focus_${DateTime.now().millisecondsSinceEpoch}_1',
      taskId: taskId,
      type: ChallengeType.focus,
      title: 'No Distractions',
      description: '15 minutes, no leaving the app. Pure focus.',
      durationMinutes: 15,
      createdAt: now,
    ));

    // Breakdown Challenge for larger tasks
    if (estimatedMinutes > 20) {
      challenges.add(Challenge(
        id: 'breakdown_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        type: ChallengeType.breakdown,
        title: '2 of 3',
        description: 'Break "$taskTitle" into 3 steps, finish 2 now in 12 minutes.',
        durationMinutes: 12,
        createdAt: now,
      ));
    }

    // Penalty Challenge for frequently snoozed tasks
    if (snoozeCount >= 2) {
      challenges.add(Challenge(
        id: 'penalty_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        type: ChallengeType.penalty,
        title: 'Penalty Bet',
        description: 'If you fail in 15m, delete 2 low-priority tasks.',
        durationMinutes: 15,
        penalty: 'Delete 2 low-priority tasks',
        createdAt: now,
      ));
    }

    // Reward Challenge
    challenges.add(Challenge(
      id: 'reward_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      type: ChallengeType.reward,
      title: 'Quick Win',
      description: 'Finish in 10m → earn a 5m break with confetti!',
      durationMinutes: 10,
      reward: '5-minute break with celebration',
      createdAt: now,
    ));

    // Time Attack for overdue tasks
    if (isOverdue) {
      challenges.add(Challenge(
        id: 'timeattack_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        type: ChallengeType.timeAttack,
        title: 'Against the Clock',
        description: '7 minutes, write 3 bullet notes or make any progress.',
        durationMinutes: 7,
        createdAt: now,
      ));
    }

    return challenges;
  }
}

