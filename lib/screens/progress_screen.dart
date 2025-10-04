import 'package:flutter/material.dart' hide showAdaptiveDialog;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/storage_service.dart';
import '../widgets/platform/adaptive_scaffold.dart';
import '../widgets/platform/adaptive_dialog.dart';
import '../widgets/platform/adaptive_card.dart';
import '../widgets/platform/adaptive_button.dart';
import '../utils/platform_helper.dart';

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

    return AdaptiveScaffold(
      title: const Text('Fortschritt'),
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
                    PlatformHelper.useIOSStyle
                        ? CupertinoIcons.flame
                        : Icons.local_fire_department,
                    size: 48,
                    color: _studyStreak > 0
                        ? (PlatformHelper.useIOSStyle
                              ? CupertinoColors.systemOrange
                              : Colors.orange)
                        : (PlatformHelper.useIOSStyle
                              ? CupertinoColors.systemGrey
                              : Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lernserie', style: TextStyle(fontSize: 16)),
                      Text(
                        '$_studyStreak Tage',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                  const Text(
                    'Gesamtgenauigkeit',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: accuracy,
                    center: Text(
                      '${(accuracy * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: _getColorForAccuracy(accuracy),
                    backgroundColor: PlatformHelper.useIOSStyle
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
                  PlatformHelper.useIOSStyle
                      ? CupertinoIcons.chat_bubble_2
                      : Icons.question_answer,
                  PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemBlue
                      : Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Richtig',
                  _stats['correctAnswers']?.toString() ?? '0',
                  PlatformHelper.useIOSStyle
                      ? CupertinoIcons.check_mark_circled
                      : Icons.check_circle,
                  PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemGreen
                      : Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Falsch',
                  _stats['incorrectAnswers']?.toString() ?? '0',
                  PlatformHelper.useIOSStyle
                      ? CupertinoIcons.xmark_circle
                      : Icons.cancel,
                  PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemRed
                      : Colors.red,
                ),
                _buildStatCard(
                  context,
                  'Sitzungen',
                  _stats['studySessions']?.toString() ?? '0',
                  PlatformHelper.useIOSStyle
                      ? CupertinoIcons.book
                      : Icons.school,
                  PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemPurple
                      : Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reset Button
            AdaptiveButton(
              onPressed: () => _showResetDialog(context),
              isDestructive: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PlatformHelper.useIOSStyle
                        ? CupertinoIcons.refresh
                        : Icons.refresh,
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
    final subtitleColor = PlatformHelper.useIOSStyle
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: subtitleColor)),
        ],
      ),
    );
  }

  Color _getColorForAccuracy(double accuracy) {
    if (PlatformHelper.useIOSStyle) {
      if (accuracy >= 0.8) return CupertinoColors.systemGreen;
      if (accuracy >= 0.6) return CupertinoColors.systemOrange;
      return CupertinoColors.systemRed;
    }
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showResetDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      title: 'Fortschritt zurücksetzen?',
      content:
          'Dies wird alle deine Lernstatistiken löschen. Diese Aktion kann nicht rückgängig gemacht werden.',
      actions: [
        AdaptiveDialogAction(
          onPressed: () => context.pop(),
          child: const Text('Abbrechen'),
        ),
        AdaptiveDialogAction(
          onPressed: () {
            _storage.clearProgress();
            context.pop();
            _loadStats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fortschritt wurde zurückgesetzt')),
            );
          },
          isDestructive: true,
          child: const Text('Zurücksetzen'),
        ),
      ],
    );
  }
}
