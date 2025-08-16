import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';

class SuccessCelebration extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onFinished;
  final bool isVisible;

  const SuccessCelebration({
    super.key,
    required this.title,
    required this.subtitle,
    this.onFinished,
    this.isVisible = true,
  });

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _startCelebration();
    }
  }

  @override
  void didUpdateWidget(SuccessCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startCelebration();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopCelebration();
    }
  }

  void _startCelebration() {
    _confettiController.play();
    _scaleController.forward();
    _fadeController.forward();

    // Auto-hide after duration
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _stopCelebration();
      }
    });
  }

  void _stopCelebration() {
    _confettiController.stop();
    _scaleController.reverse();
    _fadeController.reverse().then((_) {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isRTL = sl<ThemeService>().isRTL;

    return Stack(
      children: [
        // Background overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color:
                    Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
              );
            },
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 1.5708, // radians - 90 degrees (downward)
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.05,
            shouldLoop: false,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              theme.colorScheme.tertiary,
              Colors.orange,
              Colors.pink,
              Colors.green,
              Colors.blue,
              Colors.yellow,
            ],
          ),
        ),

        // Success content
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Success icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Celebration emojis
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBouncingEmoji('🎉', 0),
                            const SizedBox(width: 8),
                            _buildBouncingEmoji('🎊', 100),
                            const SizedBox(width: 8),
                            _buildBouncingEmoji('✨', 200),
                            const SizedBox(width: 8),
                            _buildBouncingEmoji('🎯', 300),
                            const SizedBox(width: 8),
                            _buildBouncingEmoji('💪', 400),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Close button
                        FilledButton(
                          onPressed: _stopCelebration,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            isRTL ? 'رائع!' : 'Awesome!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBouncingEmoji(String emoji, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Transform.scale(
            scale: 0.5 + (value * 0.5),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }
}

// Helper function to show success celebration
void showSuccessCelebration(
  BuildContext context, {
  required String title,
  required String subtitle,
  VoidCallback? onFinished,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => SuccessCelebration(
      title: title,
      subtitle: subtitle,
      onFinished: () {
        Navigator.of(context).pop();
        onFinished?.call();
      },
    ),
  );
}
