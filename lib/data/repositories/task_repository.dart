import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/data/adapters/task_adapter.dart';
import 'package:vanguard/data/adapters/challenge_adapter.dart';

class TaskRepository {
  static const String _tasksBoxName = 'tasks';
  static const String _challengesBoxName = 'challenges';
  
  Box<Task>? _tasksBox;
  Box<Challenge>? _challengesBox;
  
  final StreamController<List<Task>> _tasksStreamController = StreamController<List<Task>>.broadcast();
  final StreamController<List<Challenge>> _challengesStreamController = StreamController<List<Challenge>>.broadcast();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChallengeAdapter());
    }
    
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _challengesBox = await Hive.openBox<Challenge>(_challengesBoxName);
    
    // Add sample data if empty
    if (_tasksBox!.isEmpty) {
      await _addSampleTasks();
    }
    
    _emitTasks();
    _emitChallenges();
  }

  // Task operations
  Stream<List<Task>> get tasksStream => _tasksStreamController.stream;
  
  List<Task> getAllTasks() {
    return _tasksBox?.values.toList() ?? [];
  }

  List<Task> getTodayTasks() {
    final now = DateTime.now();
    return getAllTasks().where((task) => 
      task.isDueToday && task.status != TaskStatus.completed
    ).toList();
  }

  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    return getAllTasks().where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(now) && 
      !task.isDueToday &&
      task.status != TaskStatus.completed
    ).toList();
  }

  List<Task> getOverdueTasks() {
    return getAllTasks().where((task) => 
      task.isOverdue
    ).toList();
  }

  Future<void> addTask(Task task) async {
    await _tasksBox?.put(task.id, task);
    _emitTasks();
  }

  Future<void> updateTask(Task task) async {
    await _tasksBox?.put(task.id, task);
    _emitTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksBox?.delete(taskId);
    // Also delete related challenges
    final challenges = _challengesBox?.values.where((c) => c.taskId == taskId).toList() ?? [];
    for (final challenge in challenges) {
      await _challengesBox?.delete(challenge.id);
    }
    _emitTasks();
    _emitChallenges();
  }

  Task? getTask(String taskId) {
    return _tasksBox?.get(taskId);
  }

  Future<void> markTaskCompleted(String taskId) async {
    final task = getTask(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        updatedAt: DateTime.now(),
        isTimerRunning: false,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> startTimer(String taskId) async {
    final task = getTask(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(
        isTimerRunning: true,
        lastTimerStarted: DateTime.now(),
        status: TaskStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> stopTimer(String taskId) async {
    final task = getTask(taskId);
    if (task != null && task.isTimerRunning && task.lastTimerStarted != null) {
      final additionalSeconds = DateTime.now().difference(task.lastTimerStarted!).inSeconds;
      final updatedTask = task.copyWith(
        isTimerRunning: false,
        secondsSpent: task.secondsSpent + additionalSeconds,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> snoozeTask(String taskId, int minutes) async {
    final task = getTask(taskId);
    if (task != null && task.dueDate != null) {
      final newDueDate = task.dueDate!.add(Duration(minutes: minutes));
      final updatedTask = task.copyWith(
        dueDate: newDueDate,
        snoozeCount: task.snoozeCount + 1,
        lastSnoozed: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  // Challenge operations
  Stream<List<Challenge>> get challengesStream => _challengesStreamController.stream;
  
  List<Challenge> getAllChallenges() {
    return _challengesBox?.values.toList() ?? [];
  }

  List<Challenge> getChallengesForTask(String taskId) {
    return getAllChallenges().where((c) => c.taskId == taskId).toList();
  }

  Challenge? getActiveChallenge() {
    final activeChallenges = getAllChallenges().where((c) => c.status == ChallengeStatus.active);
    return activeChallenges.isEmpty ? null : activeChallenges.first;
  }

  Future<void> addChallenge(Challenge challenge) async {
    await _challengesBox?.put(challenge.id, challenge);
    _emitChallenges();
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _challengesBox?.put(challenge.id, challenge);
    _emitChallenges();
  }

  Future<void> startChallenge(String challengeId) async {
    final challenge = _challengesBox?.get(challengeId);
    if (challenge != null) {
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.active,
        startedAt: DateTime.now(),
      );
      await updateChallenge(updatedChallenge);
    }
  }

  Future<void> completeChallenge(String challengeId) async {
    final challenge = _challengesBox?.get(challengeId);
    if (challenge != null) {
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.completed,
        completedAt: DateTime.now(),
      );
      await updateChallenge(updatedChallenge);
      
      // Update task challenge stats
      final task = getTask(challenge.taskId);
      if (task != null) {
        final updatedTask = task.copyWith(
          challengesCompleted: task.challengesCompleted + 1,
          lastChallengeAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await updateTask(updatedTask);
      }
    }
  }

  Future<void> failChallenge(String challengeId) async {
    final challenge = _challengesBox?.get(challengeId);
    if (challenge != null) {
      final updatedChallenge = challenge.copyWith(
        status: ChallengeStatus.failed,
        completedAt: DateTime.now(),
      );
      await updateChallenge(updatedChallenge);
      
      // Update task challenge stats
      final task = getTask(challenge.taskId);
      if (task != null) {
        final updatedTask = task.copyWith(
          challengesFailed: task.challengesFailed + 1,
          lastChallengeAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await updateTask(updatedTask);
      }
    }
  }

  Future<void> suggestChallengesForTask(String taskId) async {
    final task = getTask(taskId);
    if (task == null || !task.shouldSuggestChallenge) return;

    // Generate challenges for this task
    final challenges = Challenge.generateChallenges(
      taskId,
      task.title,
      isOverdue: task.isOverdue,
      snoozeCount: task.snoozeCount,
      isHighPriority: task.priority == TaskPriority.high,
      estimatedMinutes: task.secondsSpent ~/ 60 + 30, // Rough estimate
    );

    // Add challenges to database
    for (final challenge in challenges.take(3)) { // Limit to 3 suggestions
      await addChallenge(challenge);
    }
  }

  void _emitTasks() {
    _tasksStreamController.add(getAllTasks());
  }
  
  void _emitChallenges() {
    _challengesStreamController.add(getAllChallenges());
  }

  Future<void> _addSampleTasks() async {
    final now = DateTime.now();
    
    final sampleTasks = [
      Task(
        id: 'task_1',
        title: 'مراجعة تقرير المشروع',
        notes: 'مراجعة التقرير النهائي للمشروع وإضافة التعديلات المطلوبة',
        dueDate: now.add(const Duration(hours: 2)),
        priority: TaskPriority.high,
        tags: ['عمل', 'مهم'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        notificationOffsets: ['120', '60', '30'],
      ),
      Task(
        id: 'task_2',
        title: 'Review Project Report',
        notes: 'Final review of the project report and add required modifications',
        dueDate: now.add(const Duration(days: 1)),
        priority: TaskPriority.medium,
        tags: ['work'],
        createdAt: now,
        updatedAt: now,
        secondsSpent: 1800, // 30 minutes
      ),
      Task(
        id: 'task_3',
        title: 'تسوق البقالة',
        notes: 'شراء المستلزمات الأسبوعية',
        dueDate: now.add(const Duration(days: 2)),
        priority: TaskPriority.low,
        tags: ['شخصي'],
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'task_4',
        title: 'Finish Flutter App',
        notes: 'Complete the remaining features and test thoroughly',
        dueDate: now.subtract(const Duration(hours: 3)), // Overdue
        priority: TaskPriority.high,
        tags: ['development', 'urgent'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        snoozeCount: 3,
        lastSnoozed: now.subtract(const Duration(minutes: 45)),
        secondsSpent: 7200, // 2 hours
      ),
      Task(
        id: 'task_5',
        title: 'تحضير العشاء',
        notes: 'تحضير وجبة عشاء صحية للعائلة',
        dueDate: now.add(const Duration(hours: 6)),
        priority: TaskPriority.medium,
        tags: ['منزل', 'طبخ'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final task in sampleTasks) {
      await addTask(task);
    }
  }

  void dispose() {
    _tasksStreamController.close();
    _challengesStreamController.close();
  }
}