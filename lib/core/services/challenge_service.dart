import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:vanguard/data/repositories/task_repository.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/core/services/notification_service.dart';

class ChallengeService extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final NotificationService _notificationService;
  
  Timer? _challengeTimer;
  Challenge? _activeChallenge;
  int _remainingSeconds = 0;
  
  ChallengeService(this._taskRepository, this._notificationService) {
    // Check for overdue/snoozed tasks every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      _checkForChallengeTriggers();
    });
  }

  Challenge? get activeChallenge => _activeChallenge;
  int get remainingSeconds => _remainingSeconds;
  bool get isChallengeActive => _challengeTimer?.isActive == true;

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressPercentage {
    if (_activeChallenge == null) return 0.0;
    final totalSeconds = _activeChallenge!.durationMinutes * 60;
    final elapsedSeconds = totalSeconds - _remainingSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  Future<List<Challenge>> generateChallengesForTask(String taskId) async {
    final task = _taskRepository.getTask(taskId);
    if (task == null) return [];

    final challenges = Challenge.generateChallenges(
      taskId,
      task.title,
      isOverdue: task.isOverdue,
      snoozeCount: task.snoozeCount,
      isHighPriority: task.priority == TaskPriority.high,
      estimatedMinutes: max(30, task.secondsSpent ~/ 60 + 15),
    );

    return challenges;
  }

  Future<Challenge> getRandomChallengeForTask(String taskId) async {
    final challenges = await generateChallengesForTask(taskId);
    if (challenges.isEmpty) {
      // Fallback challenge
      return Challenge(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        type: ChallengeType.sprint,
        title: 'Quick Sprint',
        description: 'Take 5 minutes to make any progress on this task.',
        durationMinutes: 5,
        createdAt: DateTime.now(),
      );
    }
    
    final random = Random();
    return challenges[random.nextInt(challenges.length)];
  }

  Future<void> startChallenge(Challenge challenge) async {
    // Stop any existing challenge
    if (_challengeTimer?.isActive == true) {
      await _stopCurrentChallenge();
    }

    _activeChallenge = challenge;
    _remainingSeconds = challenge.durationMinutes * 60;
    
    // Mark challenge as active in repository
    await _taskRepository.startChallenge(challenge.id);
    
    // Show challenge notification
    await _notificationService.showChallengeNotification(
      challengeTitle: challenge.title,
      challengeDescription: challenge.description,
      taskId: challenge.taskId,
    );
    
    // Start the countdown timer
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      
      // Show progress notification at halfway point
      if (_remainingSeconds == (challenge.durationMinutes * 60) ~/ 2) {
        _notificationService.showChallengeProgressNotification(
          challengeTitle: challenge.title,
          remainingMinutes: _remainingSeconds ~/ 60,
        );
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleChallengeTimeout();
      }
      
      notifyListeners();
    });
    
    notifyListeners();
  }

  Future<void> completeChallenge() async {
    if (_activeChallenge != null) {
      await _taskRepository.completeChallenge(_activeChallenge!.id);
      
      // Show success notification
      await _notificationService.showSuccessNotification(_activeChallenge!.title);
      
      await _stopCurrentChallenge();
      
      // Trigger success celebration
      _triggerSuccessCelebration();
    }
  }

  Future<void> failChallenge() async {
    if (_activeChallenge != null) {
      await _taskRepository.failChallenge(_activeChallenge!.id);
      await _stopCurrentChallenge();
      
      // Apply penalty if applicable
      if (_activeChallenge!.penalty != null) {
        _applyPenalty(_activeChallenge!.penalty!);
      }
    }
  }

  Future<void> skipChallenge() async {
    if (_activeChallenge != null) {
      final updatedChallenge = _activeChallenge!.copyWith(
        status: ChallengeStatus.skipped,
      );
      await _taskRepository.updateChallenge(updatedChallenge);
      await _stopCurrentChallenge();
    }
  }

  Future<void> _stopCurrentChallenge() async {
    _challengeTimer?.cancel();
    _activeChallenge = null;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void _handleChallengeTimeout() {
    if (_activeChallenge != null) {
      failChallenge();
    }
  }

  void _triggerSuccessCelebration() {
    // This will be handled by the UI with confetti
    // Could also trigger haptic feedback here
  }

  void _applyPenalty(String penalty) {
    // Handle penalty logic (e.g., delete low-priority tasks)
    // This is a simplified implementation
    if (penalty.contains('delete') && penalty.contains('low-priority')) {
      final lowPriorityTasks = _taskRepository.getAllTasks()
          .where((task) => 
            task.priority == TaskPriority.low && 
            task.status != TaskStatus.completed)
          .take(2)
          .toList();
      
      for (final task in lowPriorityTasks) {
        _taskRepository.deleteTask(task.id);
      }
    }
  }

  Future<void> _checkForChallengeTriggers() async {
    final tasks = _taskRepository.getAllTasks();
    
    for (final task in tasks) {
      if (task.shouldSuggestChallenge) {
        await _taskRepository.suggestChallengesForTask(task.id);
        
        // Generate and show challenge notification
        final challenge = await getRandomChallengeForTask(task.id);
        await _notificationService.showChallengeNotification(
          challengeTitle: challenge.title,
          challengeDescription: challenge.description,
          taskId: task.id,
        );
      }
    }
  }

  // Method to get suggested challenges for a task
  Future<List<Challenge>> getSuggestedChallenges(String taskId) async {
    return _taskRepository.getChallengesForTask(taskId)
        .where((c) => c.status == ChallengeStatus.suggested)
        .toList();
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    super.dispose();
  }
}