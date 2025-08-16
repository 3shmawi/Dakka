import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/data/repositories/task_repository.dart';
import 'package:vanguard/core/services/timer_service.dart';
import 'package:vanguard/core/services/challenge_service.dart';
import 'package:vanguard/core/services/notification_service.dart';

// States
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Task> todayTasks;
  final List<Task> upcomingTasks;
  final List<Task> overdueTasks;
  final List<Task> allTasks;
  final Task? activeTimerTask;
  final Challenge? activeChallenge;
  final Map<String, List<Challenge>> suggestedChallenges;

  const HomeLoaded({
    this.todayTasks = const [],
    this.upcomingTasks = const [],
    this.overdueTasks = const [],
    this.allTasks = const [],
    this.activeTimerTask,
    this.activeChallenge,
    this.suggestedChallenges = const {},
  });

  @override
  List<Object?> get props => [
    todayTasks, upcomingTasks, overdueTasks, allTasks,
    activeTimerTask, activeChallenge, suggestedChallenges,
  ];

  HomeLoaded copyWith({
    List<Task>? todayTasks,
    List<Task>? upcomingTasks,
    List<Task>? overdueTasks,
    List<Task>? allTasks,
    Task? activeTimerTask,
    Challenge? activeChallenge,
    Map<String, List<Challenge>>? suggestedChallenges,
  }) {
    return HomeLoaded(
      todayTasks: todayTasks ?? this.todayTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      allTasks: allTasks ?? this.allTasks,
      activeTimerTask: activeTimerTask ?? this.activeTimerTask,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      suggestedChallenges: suggestedChallenges ?? this.suggestedChallenges,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  final TaskRepository _taskRepository;
  final TimerService _timerService;
  final ChallengeService _challengeService;
  final NotificationService _notificationService;
  
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _challengesSubscription;

  HomeCubit({
    required TaskRepository taskRepository,
    required TimerService timerService,
    required ChallengeService challengeService,
    required NotificationService notificationService,
  }) : _taskRepository = taskRepository,
       _timerService = timerService,
       _challengeService = challengeService,
       _notificationService = notificationService,
       super(HomeInitial());

  void init() {
    emit(HomeLoading());
    
    // Listen to tasks changes
    _tasksSubscription = _taskRepository.tasksStream.listen((_) {
      _loadTasks();
    });
    
    // Listen to challenges changes
    _challengesSubscription = _taskRepository.challengesStream.listen((_) {
      _loadChallenges();
    });
    
    // Listen to timer service changes
    _timerService.addListener(_onTimerUpdate);
    
    // Listen to challenge service changes
    _challengeService.addListener(_onChallengeUpdate);
    
    _loadTasks();
  }

  void _loadTasks() {
    try {
      final todayTasks = _taskRepository.getTodayTasks();
      final upcomingTasks = _taskRepository.getUpcomingTasks();
      final overdueTasks = _taskRepository.getOverdueTasks();
      final allTasks = _taskRepository.getAllTasks();
      
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(
          todayTasks: todayTasks,
          upcomingTasks: upcomingTasks,
          overdueTasks: overdueTasks,
          allTasks: allTasks,
        ));
      } else {
        emit(HomeLoaded(
          todayTasks: todayTasks,
          upcomingTasks: upcomingTasks,
          overdueTasks: overdueTasks,
          allTasks: allTasks,
        ));
      }
    } catch (e) {
      emit(HomeError('Failed to load tasks: $e'));
    }
  }

  void _loadChallenges() async {
    if (state is HomeLoaded) {
      final suggestedChallenges = <String, List<Challenge>>{};
      final currentState = state as HomeLoaded;
      
      // Load suggested challenges for each task that needs them
      for (final task in [...currentState.todayTasks, ...currentState.overdueTasks]) {
        if (task.shouldSuggestChallenge) {
          final challenges = await _challengeService.getSuggestedChallenges(task.id);
          if (challenges.isNotEmpty) {
            suggestedChallenges[task.id] = challenges;
          }
        }
      }
      
      emit(currentState.copyWith(suggestedChallenges: suggestedChallenges));
    }
  }

  void _onTimerUpdate() {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(
        activeTimerTask: _timerService.activeTask,
      ));
    }
  }

  void _onChallengeUpdate() {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(
        activeChallenge: _challengeService.activeChallenge,
      ));
    }
  }

  // Task Actions
  Future<void> addTask(Task task) async {
    await _taskRepository.addTask(task);
    // Schedule notification for the new task
    await _notificationService.scheduleTaskNotifications(task);
  }

  Future<void> updateTask(Task task) async {
    await _taskRepository.updateTask(task);
    // Cancel previous notifications and schedule new ones
    await _notificationService.cancelTaskNotifications(task.id);
    await _notificationService.scheduleTaskNotifications(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskRepository.deleteTask(taskId);
    // Cancel notifications for deleted task
    await _notificationService.cancelTaskNotifications(taskId);
  }

  Future<void> markTaskCompleted(String taskId) async {
    await _taskRepository.markTaskCompleted(taskId);
  }

  Future<void> snoozeTask(String taskId, int minutes) async {
    await _taskRepository.snoozeTask(taskId, minutes);
  }

  // Timer Actions
  Future<void> startTimer(String taskId) async {
    await _timerService.startTimer(taskId);
  }

  Future<void> pauseTimer() async {
    await _timerService.pauseTimer();
  }

  Future<void> resumeTimer() async {
    await _timerService.resumeTimer();
  }

  Future<void> stopTimer() async {
    await _timerService.stopTimer();
  }

  // Challenge Actions
  Future<void> generateChallengeForTask(String taskId) async {
    await _taskRepository.suggestChallengesForTask(taskId);
  }

  Future<void> startChallenge(Challenge challenge) async {
    await _challengeService.startChallenge(challenge);
  }

  Future<void> completeChallenge() async {
    await _challengeService.completeChallenge();
  }

  Future<void> failChallenge() async {
    await _challengeService.failChallenge();
  }

  Future<void> skipChallenge() async {
    await _challengeService.skipChallenge();
  }

  List<Task> getTasksByFilter(TaskFilter filter) {
    if (state is! HomeLoaded) return [];
    final loadedState = state as HomeLoaded;
    
    switch (filter) {
      case TaskFilter.today:
        return loadedState.todayTasks;
      case TaskFilter.upcoming:
        return loadedState.upcomingTasks;
      case TaskFilter.overdue:
        return loadedState.overdueTasks;
      case TaskFilter.all:
        return loadedState.allTasks.where((task) => task.status != TaskStatus.completed).toList();
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _challengesSubscription?.cancel();
    _timerService.removeListener(_onTimerUpdate);
    _challengeService.removeListener(_onChallengeUpdate);
    return super.close();
  }
}

enum TaskFilter { today, upcoming, overdue, all }