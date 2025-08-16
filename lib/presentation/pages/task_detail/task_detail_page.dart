import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vanguard/data/models/task.dart';

import 'package:vanguard/presentation/pages/task_detail/task_detail_cubit.dart';
import 'package:vanguard/presentation/widgets/challenge_bottom_sheet.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final bool isEditing;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.isEditing = false,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  List<String> _selectedTags = [];
  List<String> _notificationOffsets = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes);

    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;
    _selectedTags = List.from(widget.task.tags);
    _notificationOffsets = List.from(widget.task.notificationOffsets);
    _isEditMode = widget.isEditing;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;

    return BlocProvider(
      create: (context) => TaskDetailCubit(
        taskRepository: sl(),
        challengeService: sl(),
        notificationService: sl(),
      )..loadTaskDetail(widget.task.id),
      child: Scaffold(
        appBar: _buildAppBar(context, theme, isRTL),
        body: BlocBuilder<TaskDetailCubit, TaskDetailState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildTabBar(context, theme, isRTL),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(context, state, isRTL),
                      _buildTimerTab(context, state, isRTL),
                      _buildChallengesTab(context, state, isRTL),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton:
            _isEditMode ? _buildSaveFAB(context, isRTL) : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ThemeData theme, bool isRTL) {
    return AppBar(
      title: Text(
        _isEditMode
            ? (isRTL ? 'تعديل المهمة' : 'Edit Task')
            : widget.task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        if (!_isEditMode) ...[
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
            icon: const Icon(Icons.edit),
            tooltip: isRTL ? 'تعديل' : 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'timer',
                child: ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(isRTL ? 'بدء المؤقت' : 'Start Timer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'challenge',
                child: ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: Text(isRTL ? 'بدء تحدي' : 'Start Challenge'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(
                    isRTL ? 'إكمال المهمة' : 'Complete Task',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    isRTL ? 'حذف المهمة' : 'Delete Task',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() {
                _isEditMode = false;
                // Reset values to original
                _titleController.text = widget.task.title;
                _notesController.text = widget.task.notes;
                _selectedPriority = widget.task.priority;
                _selectedDueDate = widget.task.dueDate;
                _selectedTags = List.from(widget.task.tags);
                _notificationOffsets =
                    List.from(widget.task.notificationOffsets);
              });
            },
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, ThemeData theme, bool isRTL) {
    final tabTitles = isRTL
        ? ['التفاصيل', 'المؤقت', 'التحديات']
        : ['Details', 'Timer', 'Challenges'];

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
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  Widget _buildDetailsTab(
      BuildContext context, TaskDetailState state, bool isRTL) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskStatusCard(context, theme, isRTL),
          const SizedBox(height: 24),
          _buildSectionTitle(
              context, isRTL ? 'معلومات المهمة' : 'Task Information'),
          const SizedBox(height: 16),
          _buildTaskInfoSection(context, theme, isRTL),
          const SizedBox(height: 24),
          _buildSectionTitle(
              context, isRTL ? 'الجدولة والتذكيرات' : 'Schedule & Reminders'),
          const SizedBox(height: 16),
          _buildScheduleSection(context, theme, isRTL),
          const SizedBox(height: 24),
          _buildSectionTitle(context, isRTL ? 'التصنيفات' : 'Tags'),
          const SizedBox(height: 16),
          _buildTagsSection(context, theme, isRTL),
          const SizedBox(height: 24),
          _buildSectionTitle(context, isRTL ? 'الإحصائيات' : 'Statistics'),
          const SizedBox(height: 16),
          _buildStatisticsSection(context, theme, isRTL),
        ],
      ),
    );
  }

  Widget _buildTimerTab(
      BuildContext context, TaskDetailState state, bool isRTL) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTimerDisplay(context, theme, isRTL),
          const SizedBox(height: 32),
          _buildTimerControls(context, theme, isRTL),
          const SizedBox(height: 32),
          _buildTimerHistory(context, theme, isRTL),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(
      BuildContext context, TaskDetailState state, bool isRTL) {
    if (state is TaskDetailLoaded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveChallengeCard(context, state, isRTL),
            const SizedBox(height: 24),
            _buildSuggestedChallenges(context, state, isRTL),
            const SizedBox(height: 24),
            _buildChallengeHistory(context, state, isRTL),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildTaskStatusCard(
      BuildContext context, ThemeData theme, bool isRTL) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (widget.task.status) {
      case TaskStatus.completed:
        statusColor = theme.colorScheme.secondary;
        statusText = isRTL ? 'مكتملة' : 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = theme.colorScheme.primary;
        statusText = isRTL ? 'قيد التنفيذ' : 'In Progress';
        statusIcon = Icons.play_circle;
        break;
      case TaskStatus.pending:
        statusColor = theme.colorScheme.tertiary;
        statusText = isRTL ? 'في الانتظار' : 'Pending';
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.task.dueDate != null) ...[
                  Text(
                    _formatDueDate(widget.task.dueDate!, isRTL),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.task.isOverdue) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isRTL ? 'متأخرة' : 'Overdue',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTaskInfoSection(
      BuildContext context, ThemeData theme, bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              enabled: _isEditMode,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: isRTL ? 'عنوان المهمة' : 'Task Title',
                border:
                    _isEditMode ? const OutlineInputBorder() : InputBorder.none,
                contentPadding: _isEditMode ? null : EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),
          if (_isEditMode || _notesController.text.isNotEmpty) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notesController,
                enabled: _isEditMode,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: isRTL ? 'الملاحظات' : 'Notes',
                  border: _isEditMode
                      ? const OutlineInputBorder()
                      : InputBorder.none,
                  contentPadding: _isEditMode ? null : EdgeInsets.zero,
                ),
                maxLines: null,
                minLines: 3,
              ),
            ),
          ],
          if (_isEditMode) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPrioritySelector(context, theme, isRTL),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(
      BuildContext context, ThemeData theme, bool isRTL) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRTL ? 'الأولوية' : 'Priority',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPriorityChip(
              TaskPriority.high,
              isRTL ? 'عالية' : 'High',
              Colors.red,
              theme,
            ),
            const SizedBox(width: 8),
            _buildPriorityChip(
              TaskPriority.medium,
              isRTL ? 'متوسطة' : 'Medium',
              Colors.orange,
              theme,
            ),
            const SizedBox(width: 8),
            _buildPriorityChip(
              TaskPriority.low,
              isRTL ? 'منخفضة' : 'Low',
              Colors.green,
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(
    TaskPriority priority,
    String label,
    Color color,
    ThemeData theme,
  ) {
    final isSelected = _selectedPriority == priority;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: _isEditMode
          ? (selected) {
              if (selected) {
                setState(() {
                  _selectedPriority = priority;
                });
              }
            }
          : null,
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }

  Widget _buildScheduleSection(
      BuildContext context, ThemeData theme, bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(isRTL ? 'تاريخ الاستحقاق' : 'Due Date'),
            subtitle: _selectedDueDate != null
                ? Text(_formatDueDate(_selectedDueDate!, isRTL))
                : Text(isRTL ? 'لم يتم تحديد موعد' : 'No due date set'),
            trailing: _isEditMode
                ? IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  )
                : null,
          ),
          if (_isEditMode && _selectedDueDate != null) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(isRTL ? 'التذكيرات' : 'Reminders'),
              subtitle: Text(
                _notificationOffsets.isNotEmpty
                    ? _notificationOffsets.map((e) => '${e}م').join(', ')
                    : (isRTL ? 'لا توجد تذكيرات' : 'No reminders'),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editReminders(context, isRTL),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, ThemeData theme, bool isRTL) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: _isEditMode
                            ? const Icon(Icons.close, size: 16)
                            : null,
                        onDeleted: _isEditMode
                            ? () {
                                setState(() {
                                  _selectedTags.remove(tag);
                                });
                              }
                            : null,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        side: BorderSide(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ))
                  .toList(),
            ),
          ] else ...[
            Text(
              isRTL ? 'لا توجد تصنيفات' : 'No tags',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_isEditMode) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _addTag(context, isRTL),
              icon: const Icon(Icons.add, size: 16),
              label: Text(isRTL ? 'إضافة تصنيف' : 'Add Tag'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, ThemeData theme, bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            Icons.access_time,
            isRTL ? 'الوقت المستغرق' : 'Time Spent',
            widget.task.formattedTimeSpent,
            theme,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildStatRow(
            context,
            Icons.emoji_events,
            isRTL ? 'التحديات المكتملة' : 'Challenges Completed',
            '${widget.task.challengesCompleted}',
            theme,
          ),
          if (widget.task.snoozeCount > 0) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            _buildStatRow(
              context,
              Icons.snooze,
              isRTL ? 'مرات التأجيل' : 'Times Snoozed',
              '${widget.task.snoozeCount}',
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, ThemeData theme, bool isRTL) {
    // TODO: Implement timer display
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            widget.task.formattedTimeSpent,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRTL ? 'إجمالي الوقت المستغرق' : 'Total Time Spent',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls(
      BuildContext context, ThemeData theme, bool isRTL) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.icon(
          onPressed: () {
            // TODO: Start timer
          },
          icon: Icon(
            widget.task.isTimerRunning ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            widget.task.isTimerRunning
                ? (isRTL ? 'إيقاف مؤقت' : 'Pause')
                : (isRTL ? 'بدء' : 'Start'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.task.isTimerRunning
              ? () {
                  // TODO: Stop timer
                }
              : null,
          icon: const Icon(Icons.stop),
          label: Text(isRTL ? 'إيقاف' : 'Stop'),
        ),
      ],
    );
  }

  Widget _buildTimerHistory(BuildContext context, ThemeData theme, bool isRTL) {
    // TODO: Implement timer history
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRTL ? 'سجل المؤقت' : 'Timer History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isRTL ? 'لا يوجد سجل متاح' : 'No history available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengeCard(
      BuildContext context, TaskDetailState state, bool isRTL) {
    // TODO: Show active challenge if any
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'لا يوجد تحدي نشط' : 'No Active Challenge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRTL
                      ? 'ابدأ تحدي لزيادة تحفيزك'
                      : 'Start a challenge to boost motivation',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _showChallengeBottomSheet(context),
            child: Text(isRTL ? 'بدء تحدي' : 'Start Challenge'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChallenges(
      BuildContext context, TaskDetailState state, bool isRTL) {
    // TODO: Show suggested challenges
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRTL ? 'التحديات المقترحة' : 'Suggested Challenges',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          isRTL ? 'لا توجد تحديات مقترحة' : 'No suggested challenges',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildChallengeHistory(
      BuildContext context, TaskDetailState state, bool isRTL) {
    // TODO: Show challenge history
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRTL ? 'سجل التحديات' : 'Challenge History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          isRTL ? 'لا يوجد سجل متاح' : 'No history available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildSaveFAB(BuildContext context, bool isRTL) {
    return FloatingActionButton.extended(
      onPressed: () => _saveTask(context),
      icon: const Icon(Icons.save),
      label: Text(isRTL ? 'حفظ' : 'Save'),
    );
  }

  String _formatDueDate(DateTime date, bool isRTL) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return isRTL ? 'اليوم' : 'Today';
    } else if (difference.inDays == 1) {
      return isRTL ? 'غداً' : 'Tomorrow';
    } else if (difference.inDays == -1) {
      return isRTL ? 'أمس' : 'Yesterday';
    } else if (difference.inDays > 0) {
      return isRTL
          ? 'خلال ${difference.inDays} أيام'
          : 'In ${difference.inDays} days';
    } else {
      return isRTL
          ? 'متأخر ${-difference.inDays} أيام'
          : '${-difference.inDays} days overdue';
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'timer':
        // TODO: Start timer
        break;
      case 'challenge':
        _showChallengeBottomSheet(context);
        break;
      case 'complete':
        _completeTask(context);
        break;
      case 'delete':
        _deleteTask(context);
        break;
    }
  }

  void _showChallengeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeBottomSheet(
        task: widget.task,
        onChallengeStarted: (challenge) {
          // TODO: Handle challenge started
        },
      ),
    );
  }

  void _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _editReminders(BuildContext context, bool isRTL) {
    // TODO: Show reminder editing dialog
  }

  void _addTag(BuildContext context, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(isRTL ? 'إضافة تصنيف' : 'Add Tag'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isRTL ? 'اسم التصنيف' : 'Tag name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                  setState(() {
                    _selectedTags.add(tag);
                  });
                }
                Navigator.pop(context);
              },
              child: Text(isRTL ? 'إضافة' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveTask(BuildContext context) {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      notes: _notesController.text,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      tags: _selectedTags,
      notificationOffsets: _notificationOffsets,
      updatedAt: DateTime.now(),
    );

    context.read<TaskDetailCubit>().updateTask(updatedTask);
    setState(() {
      _isEditMode = false;
    });
  }

  void _completeTask(BuildContext context) {
    context.read<TaskDetailCubit>().completeTask(widget.task.id);
    Navigator.pop(context);
  }

  void _deleteTask(BuildContext context) {
    final isRTL = sl<ThemeService>().isRTL;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'حذف المهمة' : 'Delete Task'),
        content: Text(
          isRTL
              ? 'هل أنت متأكد من حذف هذه المهمة؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TaskDetailCubit>().deleteTask(widget.task.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail page
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(isRTL ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
