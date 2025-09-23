import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../widgets/flashcard_widget.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lernkarten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<QuestionsProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isCurrentQuestionBookmarked()
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                onPressed: () {
                  provider.toggleBookmark();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Fehler: ${provider.error}'));
          }

          final question = provider.currentQuestion;
          if (question == null) {
            return const Center(child: Text('Keine Fragen verfügbar'));
          }

          return Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: provider.getProgress(),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              // Question counter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Frage ${provider.currentQuestionIndex + 1} von ${provider.currentQuestions.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              // Flashcard
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FlashcardWidget(
                    question: question,
                    onFlip: () {
                      // Track time spent on question
                    },
                  ),
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.hasPrevious
                          ? () => provider.previousQuestion()
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Zurück'),
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.hasNext
                          ? () => provider.nextQuestion()
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Weiter'),
                    ),
                  ],
                ),
              ),
              // Session stats
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Richtig',
                      provider.getSessionStats()['correct'].toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Falsch',
                      provider.getSessionStats()['incorrect'].toString(),
                      Colors.red,
                    ),
                    _buildStatItem(
                      'Offen',
                      provider.getSessionStats()['unanswered'].toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
