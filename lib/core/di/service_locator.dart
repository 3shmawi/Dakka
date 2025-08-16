import 'package:get_it/get_it.dart';
import 'package:vanguard/data/repositories/task_repository.dart';
import 'package:vanguard/core/services/timer_service.dart';
import 'package:vanguard/core/services/challenge_service.dart';
import 'package:vanguard/core/services/notification_service.dart';
import 'package:vanguard/core/services/theme_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Repositories
  sl.registerLazySingleton<TaskRepository>(() => TaskRepository());
  
  // Services
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<TimerService>(() => TimerService(sl()));
  sl.registerLazySingleton<ChallengeService>(() => ChallengeService(sl(), sl()));
  sl.registerLazySingleton<ThemeService>(() => ThemeService());

  // Initialize repository
  await sl<TaskRepository>().init();
  
  // Initialize services
  await sl<NotificationService>().init();
  await sl<ThemeService>().init();
}