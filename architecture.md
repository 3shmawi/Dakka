# Dakka - Creative To-Do App Architecture

## Core Features & MVP
1. **Task Management**: CRUD operations with title, notes, due date, priority, tags
2. **Smart Notifications**: Multiple warning offsets, snooze actions, reschedule
3. **Task Timer**: Start/pause/resume with global mini-player, Pomodoro mode
4. **Smart Challenge System**: Motivational challenges for overdue/snoozed tasks
5. **RTL Support**: Arabic as default, English secondary
6. **Theme System**: Dark/Light mode with instant switching

## Technical Architecture

### State Management
- **flutter_bloc/cubit**: Simple state management for UI
- **equatable**: Value equality for state classes

### Dependencies
- **get_it**: Dependency injection
- **go_router**: Navigation
- **hive_flutter**: Local storage with encryption
- **flutter_local_notifications + timezone**: Smart notifications
- **workmanager**: Background tasks
- **intl**: Internationalization
- **confetti**: Success animations
- **vibration**: Haptic feedback

### Data Layer
```
lib/
├── data/
│   ├── models/
│   │   ├── task.dart (Hive model)
│   │   ├── challenge.dart
│   │   └── notification_settings.dart
│   ├── repositories/
│   │   ├── task_repository.dart
│   │   ├── notification_repository.dart
│   │   └── settings_repository.dart
│   └── datasources/
│       ├── local_storage.dart (Hive)
│       └── notification_service.dart
```

### Domain Layer
```
├── domain/
│   ├── entities/
│   ├── usecases/
│   │   ├── task_usecases.dart
│   │   ├── timer_usecases.dart
│   │   └── challenge_usecases.dart
│   └── repositories/ (interfaces)
```

### Presentation Layer
```
├── presentation/
│   ├── pages/
│   │   ├── home/
│   │   │   ├── home_page.dart
│   │   │   └── home_cubit.dart
│   │   ├── task_detail/
│   │   ├── add_edit_task/
│   │   └── settings/
│   ├── widgets/
│   │   ├── task_card.dart
│   │   ├── timer_mini_player.dart
│   │   ├── challenge_bottom_sheet.dart
│   │   └── quick_add_bar.dart
│   └── theme/
```

### Core Services
```
├── core/
│   ├── services/
│   │   ├── timer_service.dart
│   │   ├── notification_service.dart
│   │   ├── challenge_service.dart
│   │   └── background_service.dart
│   ├── utils/
│   └── constants/
```

## Implementation Plan

### Phase 1: Foundation (Files 1-3)
1. Update pubspec.yaml with all dependencies
2. Setup dependency injection and routing
3. Update theme with task-focused colors

### Phase 2: Core Data & Domain (Files 4-6)
4. Create Task model with Hive integration
5. Build TaskRepository with CRUD operations
6. Setup NotificationService foundation

### Phase 3: Basic UI (Files 7-9)
7. Create HomePage with tabs (Today, Upcoming, Overdue, All)
8. Build TaskCard widget with swipe actions
9. Implement QuickAddBar component

### Phase 4: Advanced Features (Files 10-12)
10. Build TimerService with mini-player
11. Create ChallengeService with bottom sheet UI
12. Add SettingsPage with theme/language toggle

## Challenge System Logic
- **Triggers**: Overdue tasks, 2+ snoozes, 20min+ idle
- **Types**: Sprint, Focus, Breakdown, Penalty, Reward
- **Context-aware**: Task priority/duration influences challenge selection
- **Success tracking**: Badges, streaks, confetti animations

## Key Technical Decisions
- **Hive over Drift**: Simpler setup, better performance for small datasets
- **Cubit over full Bloc**: Simpler state management for this scope
- **RTL-first design**: Arabic text handling with proper font support
- **Isolate timers**: Accurate background timing
- **Local-first**: No backend dependencies, all data stored locally

## File Structure Summary
Maximum 12 files total for MVP:
1. main.dart (updated)
2. theme.dart (updated) 
3. app_router.dart
4. task.dart (model)
5. task_repository.dart
6. home_page.dart + home_cubit.dart
7. task_card.dart
8. timer_service.dart
9. challenge_service.dart
10. settings_page.dart
11. add_edit_task_sheet.dart
12. notification_service.dart