import 'package:flutter/material.dart';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';

class QuickAddBar extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const QuickAddBar({
    super.key,
    required this.onTaskAdded,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isExpanded 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded 
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: _isExpanded ? 2 : 1,
              ),
              boxShadow: _isExpanded 
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isExpanded 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isExpanded 
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  ),
                  child: Icon(
                    _isExpanded ? Icons.edit : Icons.add,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textDirection: _detectTextDirection(_controller.text),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: isRTL ? 'اكتب مهمة جديدة...' : 'Type a new task...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _addTask,
                    textInputAction: TextInputAction.done,
                    maxLines: 1,
                  ),
                ),
                if (_isExpanded || _controller.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(context, theme, isRTL),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, bool isRTL) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.text.isNotEmpty) ...[
            IconButton(
              onPressed: _addTask,
              icon: Icon(
                Icons.send,
                color: theme.colorScheme.primary,
              ),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: isRTL ? 'إضافة المهمة' : 'Add Task',
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            onPressed: _showAdvancedOptions,
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: isRTL ? 'خيارات متقدمة' : 'Advanced Options',
          ),
        ],
      ),
    );
  }

  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;
    
    // Simple RTL detection for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final hasArabic = arabicRegex.hasMatch(text);
    
    return hasArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  void _addTask([String? value]) {
    final title = (value ?? _controller.text).trim();
    if (title.isEmpty) return;

    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Create new task
    final now = DateTime.now();
    final task = Task(
      id: 'task_${now.millisecondsSinceEpoch}',
      title: title,
      createdAt: now,
      updatedAt: now,
      // Set due date to end of today for quick-added tasks
      dueDate: DateTime(now.year, now.month, now.day, 23, 59),
    );

    widget.onTaskAdded(task);
    
    // Clear the input
    _controller.clear();
    _focusNode.unfocus();

    // Show feedback
    _showAddedFeedback(title);
  }

  void _showAddedFeedback(String title) {
    final isRTL = sl<ThemeService>().isRTL;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isRTL ? 'تم إضافة "$title"' : 'Added "$title"',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: isRTL ? 'تراجع' : 'Undo',
          textColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  void _showAdvancedOptions() {
    final isRTL = sl<ThemeService>().isRTL;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  isRTL ? 'إضافة مهمة جديدة' : 'Add New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pre-fill title if something was typed
                      TextField(
                        controller: TextEditingController(text: _controller.text),
                        decoration: InputDecoration(
                          labelText: isRTL ? 'عنوان المهمة' : 'Task Title',
                          hintText: isRTL ? 'اكتب عنوان المهمة...' : 'Enter task title...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: isRTL ? 'ملاحظات (اختيارية)' : 'Notes (Optional)',
                          hintText: isRTL ? 'أضف ملاحظات...' : 'Add notes...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        maxLines: 3,
                        minLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isRTL ? 'الأولوية' : 'Priority',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPriorityChip(TaskPriority.high, isRTL ? 'عالية' : 'High', Colors.red),
                          const SizedBox(width: 8),
                          _buildPriorityChip(TaskPriority.medium, isRTL ? 'متوسطة' : 'Medium', Colors.orange),
                          const SizedBox(width: 8),
                          _buildPriorityChip(TaskPriority.low, isRTL ? 'منخفضة' : 'Low', Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Create task with advanced options
                            if (_controller.text.isNotEmpty) {
                              _addTask();
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isRTL ? 'إضافة المهمة' : 'Add Task',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, String label, Color color) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: false, // TODO: Track selected priority
      onSelected: (selected) {
        // TODO: Update selected priority
      },
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}