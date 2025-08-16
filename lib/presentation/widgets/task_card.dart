import 'package:flutter/material.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final List<Challenge> suggestedChallenges;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final Function(Task) onEdit;
  final VoidCallback onStartTimer;
  final Function(int) onSnooze;
  final Function(Challenge) onStartChallenge;
  final VoidCallback onGenerateChallenge;

  const TaskCard({
    super.key,
    required this.task,
    this.suggestedChallenges = const [],
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onStartTimer,
    required this.onSnooze,
    required this.onStartChallenge,
    required this.onGenerateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;
    
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(context, true),
      secondaryBackground: _buildDismissBackground(context, false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onDelete();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _getBorderColor(theme),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTaskDetails(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, theme, isRTL),
                  const SizedBox(height: 12),
                  _buildContent(context, theme, isRTL),
                  if (task.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildNotes(context, theme),
                  ],
                  const SizedBox(height: 12),
                  _buildFooter(context, theme, isRTL),
                  if (suggestedChallenges.isNotEmpty || task.shouldSuggestChallenge) ...[
                    const SizedBox(height: 12),
                    _buildChallengeSection(context, theme, isRTL),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isRTL) {
    return Row(
      children: [
        _buildPriorityIndicator(theme),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: task.status == TaskStatus.completed 
                ? TextDecoration.lineThrough 
                : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(theme, isRTL),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isRTL) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.dueDate != null) _buildDueDate(theme, isRTL),
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTags(theme),
              ],
            ],
          ),
        ),
        if (task.secondsSpent > 0 || task.challengesCompleted > 0) ...[
          const SizedBox(width: 12),
          _buildStatsColumn(theme, isRTL),
        ],
      ],
    );
  }

  Widget _buildNotes(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.notes,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isRTL) {
    return Row(
      children: [
        if (task.isOverdue) ...[
          _buildOverdueChip(theme, isRTL),
          const SizedBox(width: 8),
        ],
        if (task.snoozeCount > 0) ...[
          _buildSnoozeChip(theme, isRTL),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        _buildActionButtons(context, theme),
      ],
    );
  }

  Widget _buildChallengeSection(BuildContext context, ThemeData theme, bool isRTL) {
    if (suggestedChallenges.isNotEmpty) {
      final challenge = suggestedChallenges.first;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              challenge.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => onStartChallenge(challenge),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(isRTL ? 'ابدأ' : 'Start'),
            ),
          ],
        ),
      );
    } else if (task.shouldSuggestChallenge) {
      return OutlinedButton.icon(
        onPressed: onGenerateChallenge,
        icon: const Icon(Icons.flash_on, size: 16),
        label: Text(isRTL ? 'اقتراح تحدي' : 'Suggest Challenge'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.tertiary,
          side: BorderSide(color: theme.colorScheme.tertiary),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPriorityIndicator(ThemeData theme) {
    Color color;
    switch (task.priority) {
      case TaskPriority.high:
        color = theme.colorScheme.error;
        break;
      case TaskPriority.medium:
        color = theme.colorScheme.tertiary;
        break;
      case TaskPriority.low:
        color = theme.colorScheme.secondary;
        break;
    }
    
    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isRTL) {
    if (task.status == TaskStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              isRTL ? 'مكتملة' : 'Done',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDueDate(ThemeData theme, bool isRTL) {
    final now = DateTime.now();
    final isOverdue = task.isOverdue;
    final isToday = task.isDueToday;
    final isTomorrow = task.isDueTomorrow;
    
    String text;
    Color color;
    IconData icon;
    
    if (isOverdue) {
      text = isRTL ? 'متأخرة' : 'Overdue';
      color = theme.colorScheme.error;
      icon = Icons.schedule;
    } else if (isToday) {
      text = isRTL ? 'اليوم' : 'Today';
      color = theme.colorScheme.primary;
      icon = Icons.today;
    } else if (isTomorrow) {
      text = isRTL ? 'غداً' : 'Tomorrow';
      color = theme.colorScheme.tertiary;
      icon = Icons.event;
    } else {
      final difference = task.dueDate!.difference(now).inDays;
      text = isRTL ? 'خلال $difference أيام' : 'In $difference days';
      color = theme.colorScheme.onSurfaceVariant;
      icon = Icons.calendar_month;
    }
    
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(ThemeData theme) {
    return Wrap(
      spacing: 4,
      children: task.tags.take(3).map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildStatsColumn(ThemeData theme, bool isRTL) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (task.secondsSpent > 0) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 2),
              Text(
                task.formattedTimeSpent,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (task.challengesCompleted > 0) ...[
          if (task.secondsSpent > 0) const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
              Text(
                '${task.challengesCompleted}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOverdueChip(ThemeData theme, bool isRTL) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRTL ? 'متأخرة' : 'Overdue',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSnoozeChip(ThemeData theme, bool isRTL) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${task.snoozeCount}× ${isRTL ? 'مؤجلة' : 'snoozed'}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status != TaskStatus.completed) ...[
          IconButton(
            onPressed: onStartTimer,
            icon: Icon(
              task.isTimerRunning ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.primary,
            ),
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'snooze_5',
                child: Text(sl<ThemeService>().isRTL ? 'تأجيل 5 دقائق' : 'Snooze 5m'),
              ),
              PopupMenuItem(
                value: 'snooze_15',
                child: Text(sl<ThemeService>().isRTL ? 'تأجيل 15 دقيقة' : 'Snooze 15m'),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(sl<ThemeService>().isRTL ? 'تعديل' : 'Edit'),
              ),
              PopupMenuItem(
                value: 'complete',
                child: Text(sl<ThemeService>().isRTL ? 'إكمال' : 'Complete'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDismissBackground(BuildContext context, bool isComplete) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;
    
    return Container(
      decoration: BoxDecoration(
        color: isComplete ? theme.colorScheme.secondary : theme.colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isComplete 
        ? (isRTL ? Alignment.centerRight : Alignment.centerLeft)
        : (isRTL ? Alignment.centerLeft : Alignment.centerRight),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isComplete ? Icons.check : Icons.delete,
            color: isComplete ? theme.colorScheme.onSecondary : theme.colorScheme.onError,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            isComplete 
              ? (isRTL ? 'إكمال' : 'Complete')
              : (isRTL ? 'حذف' : 'Delete'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isComplete ? theme.colorScheme.onSecondary : theme.colorScheme.onError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(ThemeData theme) {
    if (task.shouldSuggestChallenge) {
      return theme.colorScheme.tertiary.withValues(alpha: 0.3);
    }
    if (task.isOverdue) {
      return theme.colorScheme.error.withValues(alpha: 0.3);
    }
    if (task.isDueToday) {
      return theme.colorScheme.primary.withValues(alpha: 0.3);
    }
    return theme.colorScheme.outline.withValues(alpha: 0.2);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'snooze_5':
        onSnooze(5);
        break;
      case 'snooze_15':
        onSnooze(15);
        break;
      case 'edit':
        _showTaskDetails(context);
        break;
      case 'complete':
        onComplete();
        break;
    }
  }

  void _showTaskDetails(BuildContext context) {
    // This will be implemented when we add the task detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sl<ThemeService>().isRTL ? 'تفاصيل المهمة قريباً...' : 'Task details coming soon...',
        ),
      ),
    );
  }
}