import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../repositories/question_repository.dart';
import '../services/database_helper.dart';
import '../services/daily_goal_service.dart';
import '../models/daily_goal.dart';
import '../widgets/platform/adaptive_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final QuestionRepository _repository = QuestionRepository();
  final DailyGoalService _dailyGoalService = DailyGoalService();
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  int _studyStreak = 0;
  bool _isLoading = true;
  DailyGoal? _todayGoal;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final progress = await _repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      // Calculate study streak from daily goals service
      final studyStreak = await _dailyGoalService.getStreak();

      // Load today's goal
      final todayGoal = await _dailyGoalService.getTodayGoal();

      setState(() {
        _totalQuestions = (overall['total'] as int?) ?? 0;
        _correctAnswers = (overall['correct'] as int?) ?? 0;
        _incorrectAnswers = (overall['incorrect'] as int?) ?? 0;
        _studyStreak = studyStreak;
        _todayGoal = todayGoal;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _totalQuestions > 0
        ? (_correctAnswers / _totalQuestions)
        : 0.0;
    final isIOS = isCupertino(context);

    if (_isLoading) {
      return PlatformScaffold(
        appBar: const PlatformAppBar(title: Text('Fortschritt')),
        body: Center(
          child: isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
    }

    return PlatformScaffold(
      appBar: const PlatformAppBar(title: Text('Fortschritt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Goal Progress Card
            if (_dailyGoalService.areGoalsEnabled() && _todayGoal != null)
              AdaptiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Heutiges Ziel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isIOS
                                ? CupertinoColors.label.resolveFrom(context)
                                : null,
                          ),
                        ),
                        Icon(
                          _todayGoal!.isAchieved
                              ? (isIOS
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : Icons.check_circle)
                              : (isIOS
                                    ? CupertinoIcons.circle
                                    : Icons.circle_outlined),
                          color: _todayGoal!.isAchieved
                              ? (isIOS
                                    ? CupertinoColors.systemGreen
                                    : Colors.green)
                              : (isIOS
                                    ? CupertinoColors.systemGrey
                                    : Colors.grey),
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_todayGoal!.completedQuestions} / ${_todayGoal!.targetQuestions} Fragen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isIOS
                            ? CupertinoColors.label.resolveFrom(context)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 12,
                      percent: _todayGoal!.progress.clamp(0.0, 1.0),
                      backgroundColor: isIOS
                          ? CupertinoColors.systemGrey5.resolveFrom(context)
                          : Colors.grey.shade200,
                      progressColor: _todayGoal!.isAchieved
                          ? (isIOS ? CupertinoColors.systemGreen : Colors.green)
                          : (isIOS ? CupertinoColors.activeBlue : Colors.blue),
                      barRadius: const Radius.circular(6),
                    ),
                    if (_todayGoal!.isAchieved) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🎉 Ziel erreicht!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isIOS
                              ? CupertinoColors.systemGreen.resolveFrom(context)
                              : Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (_dailyGoalService.areGoalsEnabled() && _todayGoal != null)
              const SizedBox(height: 16),

            // Study Streak Card
            AdaptiveCard(
              child: Row(
                children: [
                  Icon(
                    isIOS ? CupertinoIcons.flame : Icons.local_fire_department,
                    size: 48,
                    color: _studyStreak > 0
                        ? (isIOS ? CupertinoColors.systemOrange : Colors.orange)
                        : (isIOS ? CupertinoColors.systemGrey : Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lernserie',
                        style: TextStyle(
                          fontSize: 16,
                          color: isIOS
                              ? CupertinoColors.label.resolveFrom(context)
                              : null,
                        ),
                      ),
                      Text(
                        '$_studyStreak Tage',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isIOS
                              ? CupertinoColors.label.resolveFrom(context)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Accuracy Card
            AdaptiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Gesamtgenauigkeit',
                    style: TextStyle(
                      fontSize: 18,
                      color: isIOS
                          ? CupertinoColors.label.resolveFrom(context)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: accuracy,
                    center: Text(
                      '${(accuracy * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isIOS
                            ? CupertinoColors.label.resolveFrom(context)
                            : null,
                      ),
                    ),
                    progressColor: _getColorForAccuracy(accuracy, isIOS),
                    backgroundColor: isIOS
                        ? CupertinoColors.systemGrey5.resolveFrom(context)
                        : Colors.grey.shade200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  context,
                  'Beantwortet',
                  _totalQuestions.toString(),
                  isIOS ? CupertinoIcons.chat_bubble_2 : Icons.question_answer,
                  isIOS ? CupertinoColors.systemBlue : Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Richtig',
                  _correctAnswers.toString(),
                  isIOS
                      ? CupertinoIcons.check_mark_circled
                      : Icons.check_circle,
                  isIOS ? CupertinoColors.systemGreen : Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Falsch',
                  _incorrectAnswers.toString(),
                  isIOS ? CupertinoIcons.xmark_circle : Icons.cancel,
                  isIOS ? CupertinoColors.systemRed : Colors.red,
                ),
                _buildStatCard(
                  context,
                  'Lerntage',
                  _studyStreak.toString(),
                  isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                  isIOS ? CupertinoColors.systemPurple : Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reset Button
            PlatformElevatedButton(
              onPressed: () => _showResetDialog(context),
              material: (context, platform) => MaterialElevatedButtonData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              cupertino: (context, platform) => CupertinoElevatedButtonData(
                color: CupertinoColors.destructiveRed,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIOS ? CupertinoIcons.refresh : Icons.refresh,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Fortschritt zurücksetzen'),
                ],
              ),
            ),
          ],
        ),
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
    final isIOS = isCupertino(context);
    final subtitleColor = isIOS
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Colors.grey[600];

    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isIOS ? CupertinoColors.label.resolveFrom(context) : null,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: subtitleColor)),
        ],
      ),
    );
  }

  Color _getColorForAccuracy(double accuracy, bool isIOS) {
    if (isIOS) {
      if (accuracy >= 0.8) return CupertinoColors.systemGreen;
      if (accuracy >= 0.6) return CupertinoColors.systemOrange;
      return CupertinoColors.systemRed;
    }
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showResetDialog(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('Fortschritt zurücksetzen?'),
        content: const Text(
          'Dies wird alle deine Lernstatistiken löschen. Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => context.pop(),
            child: const Text('Abbrechen'),
          ),
          PlatformDialogAction(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                // Clear progress from database
                final db = await DatabaseHelper.instance.database;
                await db.delete(DatabaseHelper.tableProgress);
                await db.delete(DatabaseHelper.tableBookmarks);

                navigator.pop();
                await _loadStats();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Fortschritt wurde zurückgesetzt'),
                  ),
                );
              } catch (e) {
                debugPrint('Error resetting progress: $e');
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Fehler beim Zurücksetzen')),
                );
              }
            },
            material: (context, platform) => MaterialDialogActionData(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            cupertino: (context, platform) =>
                CupertinoDialogActionData(isDestructiveAction: true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}
