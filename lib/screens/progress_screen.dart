import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/storage_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fortschritt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study Streak Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 48,
                      color: _studyStreak > 0 ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lernserie',
                          style: TextStyle(fontSize: 16),
                        ),
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
            ),
            const SizedBox(height: 16),
            
            // Accuracy Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
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
                  'Beantwortet',
                  _stats['totalQuestions']?.toString() ?? '0',
                  Icons.question_answer,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Richtig',
                  _stats['correctAnswers']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Falsch',
                  _stats['incorrectAnswers']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
                _buildStatCard(
                  'Sitzungen',
                  _stats['studySessions']?.toString() ?? '0',
                  Icons.school,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reset Button
            OutlinedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Fortschritt zurücksetzen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForAccuracy(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fortschritt zurücksetzen?'),
          content: const Text(
            'Dies wird alle deine Lernstatistiken löschen. Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                _storage.clearProgress();
                Navigator.pop(context);
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fortschritt wurde zurückgesetzt'),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Zurücksetzen'),
            ),
          ],
        );
      },
    );
  }
}