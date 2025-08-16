import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vanguard/presentation/pages/home/home_cubit.dart';
import 'package:vanguard/presentation/widgets/task_card.dart';
import 'package:vanguard/presentation/widgets/quick_add_bar.dart';
import 'package:vanguard/presentation/widgets/timer_mini_player.dart';
import 'package:vanguard/presentation/widgets/challenge_bottom_sheet.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<String> _tabTitlesAr = ['اليوم', 'القادمة', 'متأخرة', 'الكل'];
  final List<String> _tabTitlesEn = ['Today', 'Upcoming', 'Overdue', 'All'];
  final List<TaskFilter> _filters = [
    TaskFilter.today,
    TaskFilter.upcoming,
    TaskFilter.overdue,
    TaskFilter.all,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = sl<ThemeService>();
    final isRTL = themeService.isRTL;

    return BlocProvider(
      create: (context) => HomeCubit(
        taskRepository: sl(),
        timerService: sl(),
        challengeService: sl(),
        notificationService: sl(),
      )..init(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildAppBar(context, isRTL),
                  _buildTimerMiniPlayer(context, state),
                  _buildTabBar(context, isRTL),
                  _buildQuickAddBar(context),
                  Expanded(
                    child: _buildTaskList(context, state),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRTL ? 'أهلاً بك في دقة' : 'Welcome to Dakka',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRTL ? 'حان وقت الإنجاز!' : 'Time to get things done!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showSettingsBottomSheet(context),
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerMiniPlayer(BuildContext context, HomeState state) {
    if (state is HomeLoaded &&
        (state.activeTimerTask != null || state.activeChallenge != null)) {
      return TimerMiniPlayer(
        activeTask: state.activeTimerTask,
        activeChallenge: state.activeChallenge,
        onStop: () => context.read<HomeCubit>().stopTimer(),
        onPause: () => context.read<HomeCubit>().pauseTimer(),
        onResume: () => context.read<HomeCubit>().resumeTimer(),
        onCompleteChallenge: () =>
            context.read<HomeCubit>().completeChallenge(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTabBar(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);
    final tabTitles = isRTL ? _tabTitlesAr : _tabTitlesEn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary,
        ),
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        dividerColor: Colors.transparent,
        tabs: tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  Widget _buildQuickAddBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: QuickAddBar(
        onTaskAdded: (task) => context.read<HomeCubit>().addTask(task),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, HomeState state) {
    if (state is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HomeError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is HomeLoaded) {
      final tasks =
          context.read<HomeCubit>().getTasksByFilter(_filters[_currentIndex]);

      if (tasks.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final suggestedChallenges = state.suggestedChallenges[task.id] ?? [];

          return Padding(
            padding:
                EdgeInsets.only(bottom: index == tasks.length - 1 ? 100 : 16),
            child: TaskCard(
              task: task,
              suggestedChallenges: suggestedChallenges,
              onComplete: () =>
                  context.read<HomeCubit>().markTaskCompleted(task.id),
              onDelete: () => context.read<HomeCubit>().deleteTask(task.id),
              onEdit: (updatedTask) =>
                  context.read<HomeCubit>().updateTask(updatedTask),
              onStartTimer: () => context.read<HomeCubit>().startTimer(task.id),
              onSnooze: (minutes) =>
                  context.read<HomeCubit>().snoozeTask(task.id, minutes),
              onStartChallenge: (challenge) =>
                  _showChallengeBottomSheet(context, challenge),
              onGenerateChallenge: () =>
                  context.read<HomeCubit>().generateChallengeForTask(task.id),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = sl<ThemeService>();
    final isRTL = themeService.isRTL;

    final messages = {
      0: isRTL ? 'لا توجد مهام لليوم!' : 'No tasks for today!',
      1: isRTL ? 'لا توجد مهام قادمة' : 'No upcoming tasks',
      2: isRTL ? 'رائع! لا توجد مهام متأخرة' : 'Great! No overdue tasks',
      3: isRTL ? 'لا توجد مهام بعد' : 'No tasks yet',
    };

    final emojis = ['📅', '⏰', '✨', '📝'];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emojis[_currentIndex],
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            messages[_currentIndex] ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isRTL ? 'اضغط + لإضافة مهمة جديدة' : 'Tap + to add a new task',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final themeService = sl<ThemeService>();
    final isRTL = themeService.isRTL;

    return FloatingActionButton.extended(
      onPressed: () => _showAddTaskBottomSheet(context),
      icon: const Icon(Icons.add),
      label: Text(isRTL ? 'إضافة مهمة' : 'Add Task'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                sl<ThemeService>().isRTL ? 'إضافة مهمة جديدة' : 'Add New Task',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Add task form will be implemented here
              const Expanded(
                child: Center(
                  child: Text('Task form coming soon...'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChallengeBottomSheet(BuildContext context, challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeBottomSheet(
        challenge: challenge,
        onStart: () => context.read<HomeCubit>().startChallenge(challenge),
        onSkip: () => context.read<HomeCubit>().skipChallenge(),
        onSwitch: () => context
            .read<HomeCubit>()
            .generateChallengeForTask(challenge.taskId),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              sl<ThemeService>().isRTL ? 'الإعدادات' : 'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: sl<ThemeService>(),
              builder: (context, _) {
                final themeService = sl<ThemeService>();
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(themeService.isRTL ? 'اللغة' : 'Language'),
                      subtitle: Text(themeService.isRTL ? 'عربي' : 'English'),
                      onTap: () {
                        themeService.toggleLanguage();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(themeService.isRTL ? 'المظهر' : 'Theme'),
                      subtitle: Text(themeService.getThemeModeDisplayName()),
                      onTap: () {
                        themeService.toggleTheme();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
