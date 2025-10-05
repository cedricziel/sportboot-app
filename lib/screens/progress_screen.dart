import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../services/storage_service.dart';
import '../widgets/platform/adaptive_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storage = StorageService();
  Map<String, int> _stats = {};
  int _studyStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = _storage.getAllStatistics();
      _studyStreak = _storage.getStudyStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _stats['totalQuestions'] ?? 0;
    final correct = _stats['correctAnswers'] ?? 0;
    final accuracy = total > 0 ? (correct / total) : 0.0;
    final isIOS = isCupertino(context);

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
                  _stats['totalQuestions']?.toString() ?? '0',
                  isIOS ? CupertinoIcons.chat_bubble_2 : Icons.question_answer,
                  isIOS ? CupertinoColors.systemBlue : Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Richtig',
                  _stats['correctAnswers']?.toString() ?? '0',
                  isIOS
                      ? CupertinoIcons.check_mark_circled
                      : Icons.check_circle,
                  isIOS ? CupertinoColors.systemGreen : Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Falsch',
                  _stats['incorrectAnswers']?.toString() ?? '0',
                  isIOS ? CupertinoIcons.xmark_circle : Icons.cancel,
                  isIOS ? CupertinoColors.systemRed : Colors.red,
                ),
                _buildStatCard(
                  context,
                  'Sitzungen',
                  _stats['studySessions']?.toString() ?? '0',
                  isIOS ? CupertinoIcons.book : Icons.school,
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
            onPressed: () {
              _storage.clearProgress();
              context.pop();
              _loadStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fortschritt wurde zurückgesetzt'),
                ),
              );
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
