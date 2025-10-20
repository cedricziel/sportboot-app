import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/platform_helper.dart';

class GoalAchievedScreen extends StatefulWidget {
  final int streak;
  final int questionsCompleted;
  final String message;

  const GoalAchievedScreen({
    super.key,
    required this.streak,
    required this.questionsCompleted,
    required this.message,
  });

  @override
  State<GoalAchievedScreen> createState() => _GoalAchievedScreenState();
}

class _GoalAchievedScreenState extends State<GoalAchievedScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformHelper.useIOSStyle;
    final backgroundColor = isIOS
        ? CupertinoColors.systemBackground.resolveFrom(context)
        : Theme.of(context).scaffoldBackgroundColor;

    return PlatformScaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy icon with animation
                    Icon(
                          Icons.emoji_events,
                          size: 120,
                          color: isIOS
                              ? CupertinoColors.systemYellow
                              : Colors.amber,
                        )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 32),

                    // Congratulations message
                    Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isIOS
                                ? CupertinoColors.label.resolveFrom(context)
                                : Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 48),

                    // Statistics cards
                    _buildStatCard(
                          context,
                          'Heutige Fragen',
                          widget.questionsCompleted.toString(),
                          isIOS
                              ? CupertinoIcons.checkmark_circle_fill
                              : Icons.check_circle,
                          isIOS ? CupertinoColors.systemGreen : Colors.green,
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildStatCard(
                          context,
                          'Lernserie',
                          '${widget.streak} Tage',
                          isIOS
                              ? CupertinoIcons.flame_fill
                              : Icons.local_fire_department,
                          isIOS ? CupertinoColors.systemOrange : Colors.orange,
                        )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 48),

                    // Continue button
                    SizedBox(
                          width: double.infinity,
                          child: PlatformElevatedButton(
                            onPressed: () => context.pop(),
                            material: (context, platform) =>
                                MaterialElevatedButtonData(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            cupertino: (context, platform) =>
                                CupertinoElevatedButtonData(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                            child: const Text(
                              'Weiter lernen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Downward
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isIOS = PlatformHelper.useIOSStyle;

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isIOS
            ? CupertinoColors.secondarySystemBackground.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isIOS
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isIOS
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isIOS
                        ? CupertinoColors.label.resolveFrom(context)
                        : Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
  }
}
