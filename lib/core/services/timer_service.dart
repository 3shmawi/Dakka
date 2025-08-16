import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vanguard/data/repositories/task_repository.dart';
import 'package:vanguard/data/models/task.dart';

class TimerService extends ChangeNotifier {
  final TaskRepository _taskRepository;
  
  Timer? _timer;
  Task? _activeTask;
  int _elapsedSeconds = 0;
  
  TimerService(this._taskRepository);

  Task? get activeTask => _activeTask;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _timer?.isActive == true;

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> startTimer(String taskId) async {
    // Stop current timer if running
    if (_timer?.isActive == true) {
      await stopTimer();
    }

    final task = _taskRepository.getTask(taskId);
    if (task == null) return;

    _activeTask = task;
    _elapsedSeconds = 0;
    
    // Update task in repository
    await _taskRepository.startTimer(taskId);
    
    // Start the timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
    
    notifyListeners();
  }

  Future<void> pauseTimer() async {
    if (_timer?.isActive == true && _activeTask != null) {
      _timer?.cancel();
      
      // Update task with accumulated time
      await _taskRepository.stopTimer(_activeTask!.id);
      
      notifyListeners();
    }
  }

  Future<void> resumeTimer() async {
    if (_activeTask != null && _timer?.isActive != true) {
      await _taskRepository.startTimer(_activeTask!.id);
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        notifyListeners();
      });
      
      notifyListeners();
    }
  }

  Future<void> stopTimer() async {
    if (_activeTask != null) {
      _timer?.cancel();
      
      // Update task with accumulated time
      await _taskRepository.stopTimer(_activeTask!.id);
      
      _activeTask = null;
      _elapsedSeconds = 0;
      
      notifyListeners();
    }
  }

  Future<void> completeTask() async {
    if (_activeTask != null) {
      await _taskRepository.markTaskCompleted(_activeTask!.id);
      await stopTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}