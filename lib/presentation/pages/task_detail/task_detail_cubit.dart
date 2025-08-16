import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/data/repositories/task_repository.dart';
import 'package:vanguard/core/services/challenge_service.dart';
import 'package:vanguard/core/services/notification_service.dart';

// States
abstract class TaskDetailState extends Equatable {
  const TaskDetailState();
  @override
  List<Object?> get props => [];
}

class TaskDetailInitial extends TaskDetailState {}

class TaskDetailLoading extends TaskDetailState {}

class TaskDetailLoaded extends TaskDetailState {
  final Task task;
  final List<Challenge> challenges;
  final Challenge? activeChallenge;
  final bool isTimerRunning;
  final int secondsElapsed;

  const TaskDetailLoaded({
    required this.task,
    this.challenges = const [],
    this.activeChallenge,
    this.isTimerRunning = false,
    this.secondsElapsed = 0,
  });

  @override
  List<Object?> get props => [
        task,
        challenges,
        activeChallenge,
        isTimerRunning,
        secondsElapsed,
      ];

  TaskDetailLoaded copyWith({
    Task? task,
    List<Challenge>? challenges,
    Challenge? activeChallenge,
    bool? isTimerRunning,
    int? secondsElapsed,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      challenges: challenges ?? this.challenges,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
    );
  }
}

class TaskDetailError extends TaskDetailState {
  final String message;
  const TaskDetailError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskRepository _taskRepository;
  final ChallengeService _challengeService;
  final NotificationService _notificationService;

  StreamSubscription? _taskSubscription;
  StreamSubscription? _challengeSubscription;
  Timer? _timerSubscription;

  TaskDetailCubit({
    required TaskRepository taskRepository,
    required ChallengeService challengeService,
    required NotificationService notificationService,
  })  : _taskRepository = taskRepository,
        _challengeService = challengeService,
        _notificationService = notificationService,
        super(TaskDetailInitial());

  void loadTaskDetail(String taskId) {
    emit(TaskDetailLoading());

    try {
      // Listen to task changes
      _taskSubscription = _taskRepository.tasksStream.listen((_) {
        _loadTaskData(taskId);
      });

      // Listen to challenge changes
      _challengeSubscription = _taskRepository.challengesStream.listen((_) {
        _loadChallengeData(taskId);
      });

      // Start periodic timer updates
      _timerSubscription = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimerData(taskId);
      });

      _loadTaskData(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to load task: $e'));
    }
  }

  void _loadTaskData(String taskId) {
    final task = _taskRepository.getTask(taskId);
    if (task != null) {
      final challenges = _taskRepository.getChallengesForTask(taskId);
      final activeChallenge = _challengeService.activeChallenge;

      if (state is TaskDetailLoaded) {
        emit((state as TaskDetailLoaded).copyWith(
          task: task,
          challenges: challenges,
          activeChallenge: activeChallenge,
        ));
      } else {
        emit(TaskDetailLoaded(
          task: task,
          challenges: challenges,
          activeChallenge: activeChallenge,
          isTimerRunning: task.isTimerRunning,
        ));
      }
    } else {
      emit(const TaskDetailError('Task not found'));
    }
  }

  void _loadChallengeData(String taskId) {
    if (state is TaskDetailLoaded) {
      final challenges = _taskRepository.getChallengesForTask(taskId);
      final activeChallenge = _challengeService.activeChallenge;

      emit((state as TaskDetailLoaded).copyWith(
        challenges: challenges,
        activeChallenge: activeChallenge,
      ));
    }
  }

  void _updateTimerData(String taskId) {
    if (state is TaskDetailLoaded) {
      final currentState = state as TaskDetailLoaded;
      final task = _taskRepository.getTask(taskId);

      if (task != null &&
          task.isTimerRunning &&
          task.lastTimerStarted != null) {
        final secondsElapsed =
            DateTime.now().difference(task.lastTimerStarted!).inSeconds;

        emit(currentState.copyWith(
          task: task,
          isTimerRunning: true,
          secondsElapsed: task.secondsSpent + secondsElapsed,
        ));
      } else if (task != null) {
        emit(currentState.copyWith(
          task: task,
          isTimerRunning: false,
          secondsElapsed: task.secondsSpent,
        ));
      }
    }
  }

  // Task Actions
  Future<void> updateTask(Task task) async {
    try {
      await _taskRepository.updateTask(task);

      // Update notifications if due date changed
      await _notificationService.cancelTaskNotifications(task.id);
      if (task.dueDate != null) {
        await _notificationService.scheduleTaskNotifications(task);
      }
    } catch (e) {
      emit(TaskDetailError('Failed to update task: $e'));
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await _taskRepository.markTaskCompleted(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to complete task: $e'));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskRepository.deleteTask(taskId);
      await _notificationService.cancelTaskNotifications(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to delete task: $e'));
    }
  }

  // Timer Actions
  Future<void> startTimer(String taskId) async {
    try {
      await _taskRepository.startTimer(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to start timer: $e'));
    }
  }

  Future<void> stopTimer(String taskId) async {
    try {
      await _taskRepository.stopTimer(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to stop timer: $e'));
    }
  }

  // Challenge Actions
  Future<void> generateChallenges(String taskId) async {
    try {
      await _taskRepository.suggestChallengesForTask(taskId);
    } catch (e) {
      emit(TaskDetailError('Failed to generate challenges: $e'));
    }
  }

  Future<void> startChallenge(Challenge challenge) async {
    try {
      await _challengeService.startChallenge(challenge);
    } catch (e) {
      emit(TaskDetailError('Failed to start challenge: $e'));
    }
  }

  Future<void> completeChallenge() async {
    try {
      await _challengeService.completeChallenge();
    } catch (e) {
      emit(TaskDetailError('Failed to complete challenge: $e'));
    }
  }

  Future<void> failChallenge() async {
    try {
      await _challengeService.failChallenge();
    } catch (e) {
      emit(TaskDetailError('Failed to fail challenge: $e'));
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    _challengeSubscription?.cancel();
    _timerSubscription?.cancel();
    return super.close();
  }
}
