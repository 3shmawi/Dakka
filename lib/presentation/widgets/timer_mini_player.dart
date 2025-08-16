import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:vanguard/data/models/task.dart';
import 'package:vanguard/data/models/challenge.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';
import 'package:vanguard/core/services/timer_service.dart';
import 'package:vanguard/core/services/challenge_service.dart';

class TimerMiniPlayer extends StatefulWidget {
  final Task? activeTask;
  final Challenge? activeChallenge;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCompleteChallenge;

  const TimerMiniPlayer({
    super.key,
    this.activeTask,
    this.activeChallenge,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onCompleteChallenge,
  });

  @override
  State<TimerMiniPlayer> createState() => _TimerMiniPlayerState();
}

class _TimerMiniPlayerState extends State<TimerMiniPlayer> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeTask == null && widget.activeChallenge == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.activeChallenge != null
            ? _buildChallengePlayer(context)
            : _buildTimerPlayer(context),
      ),
    );
  }

  Widget _buildTimerPlayer(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;
    final timerService = sl<TimerService>();
    
    return ListenableBuilder(
      listenable: timerService,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: timerService.isRunning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activeTask?.title ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timerService.formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        if (timerService.isRunning) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRTL ? 'يعمل' : 'Running',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildTimerControls(context, theme, isRTL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengePlayer(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;
    final challengeService = sl<ChallengeService>();
    final challenge = widget.activeChallenge!;
    
    return ListenableBuilder(
      listenable: challengeService,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              challenge.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              challenge.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRTL ? 'تحدي' : 'Challenge',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              challengeService.formattedRemainingTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [const FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRTL ? 'متبقي' : 'left',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildChallengeControls(context, theme, isRTL),
                ],
              ),
              const SizedBox(height: 12),
              _buildProgressBar(context, theme, challengeService.progressPercentage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerControls(BuildContext context, ThemeData theme, bool isRTL) {
    final timerService = sl<TimerService>();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: timerService.isRunning ? widget.onPause : widget.onResume,
          icon: Icon(
            timerService.isRunning ? Icons.pause : Icons.play_arrow,
            color: theme.colorScheme.primary,
          ),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: timerService.isRunning 
            ? (isRTL ? 'إيقاف مؤقت' : 'Pause')
            : (isRTL ? 'متابعة' : 'Resume'),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: widget.onStop,
          icon: Icon(
            Icons.stop,
            color: theme.colorScheme.error,
          ),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: isRTL ? 'إيقاف' : 'Stop',
        ),
      ],
    );
  }

  Widget _buildChallengeControls(BuildContext context, ThemeData theme, bool isRTL) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onCompleteChallenge,
          icon: Icon(
            Icons.check,
            color: theme.colorScheme.secondary,
          ),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: isRTL ? 'إكمال التحدي' : 'Complete Challenge',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => sl<ChallengeService>().failChallenge(),
          icon: Icon(
            Icons.close,
            color: theme.colorScheme.error,
          ),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: isRTL ? 'إنهاء التحدي' : 'End Challenge',
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, ThemeData theme, double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.activeChallenge != null) {
      return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3);
    }
    
    return theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  }
}