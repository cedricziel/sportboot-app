import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../repositories/question_repository.dart';
import '../services/database_helper.dart';
import '../widgets/platform/adaptive_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final QuestionRepository _repository = QuestionRepository();
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  int _studyStreak = 0;
  bool _isLoading = true;

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

      // Calculate study streak from database
      final studyStreak = await _calculateStudyStreak();

      setState(() {
        _totalQuestions = (overall['total'] as int?) ?? 0;
        _correctAnswers = (overall['correct'] as int?) ?? 0;
        _incorrectAnswers = (overall['incorrect'] as int?) ?? 0;
        _studyStreak = studyStreak;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _calculateStudyStreak() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get the last study date from progress table
      final result = await db.rawQuery('''
        SELECT MAX(last_answered_at) as last_study
        FROM ${DatabaseHelper.tableProgress}
      ''');

      final lastStudyMillis = result.first['last_study'] as int?;
      if (lastStudyMillis == null) return 0;

      final lastStudyDate = DateTime.fromMillisecondsSinceEpoch(
        lastStudyMillis,
      );
      final today = DateTime.now();
      final difference = today.difference(lastStudyDate).inDays;

      // If studied today or yesterday, consider it as maintaining streak
      if (difference <= 1) {
        // Count consecutive days with activity
        int streak = 0;
        DateTime checkDate = DateTime(today.year, today.month, today.day);

        for (int i = 0; i < 365; i++) {
          // Check up to 1 year
          final dayStart = checkDate
              .subtract(Duration(days: i))
              .millisecondsSinceEpoch;
          final dayEnd = dayStart + 86400000; // 24 hours in milliseconds

          final dayResult = await db.rawQuery(
            '''
            SELECT COUNT(*) as count
            FROM ${DatabaseHelper.tableProgress}
            WHERE last_answered_at >= ? AND last_answered_at < ?
          ''',
            [dayStart, dayEnd],
          );

          final count = (dayResult.first['count'] as int?) ?? 0;
          if (count > 0) {
            streak++;
          } else {
            break; // Streak broken
          }
        }

        return streak;
      }

      return 0; // Streak broken if more than 1 day ago
    } catch (e) {
      debugPrint('Error calculating study streak: $e');
      return 0;
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
