import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../widgets/answer_option_widget.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? selectedAnswer;
  bool showResult = false;

  void _showQuizCompletionDialog(
    BuildContext context,
    QuestionsProvider provider,
  ) {
    final stats = provider.getSessionStats();
    final totalQuestions = provider.currentQuestions.length;
    final correctAnswers = stats['correct'] ?? 0;
    final incorrectAnswers = stats['incorrect'] ?? 0;
    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;

    provider.endSession();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Text('Quiz beendet!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deine Ergebnisse:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Richtig',
                    correctAnswers.toString(),
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Falsch',
                    incorrectAnswers.toString(),
                    Colors.red,
                  ),
                  _buildStatItem('Prozent', '$percentage%', Colors.blue),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: correctAnswers / totalQuestions,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 80
                      ? Colors.green
                      : percentage >= 60
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                percentage >= 80
                    ? 'Ausgezeichnet! 🎉'
                    : percentage >= 60
                    ? 'Gut gemacht! 👍'
                    : 'Weiter üben! 💪',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();

                // Start a new quick quiz
                final newProvider = context.read<QuestionsProvider>();
                await newProvider.loadRandomQuestions(14);
                newProvider.startSession('quiz', 'quick_quiz');

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                }
              },
              child: const Text('Neues Quiz'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Zurück zum Menü'),
            ),
          ],
        );
      },
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
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz-Modus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = provider.currentQuestion;
          if (question == null) {
            return const Center(child: Text('Keine Fragen verfügbar'));
          }

          return Column(
            children: [
              LinearProgressIndicator(
                value: provider.getProgress(),
                backgroundColor: Colors.grey[300],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Frage ${provider.currentQuestionIndex + 1} von ${provider.currentQuestions.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                question.question,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (question.assets.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ...question.assets.map(
                                  (asset) => Image.asset(
                                    'assets/images/${asset.split('/').last}',
                                    height: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        color: Colors.grey[200],
                                        child: Text(
                                          'Bild: ${asset.split('/').last}',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;

                        return AnswerOptionWidget(
                          option: option,
                          index: index,
                          isSelected: selectedAnswer == index,
                          showResult: showResult,
                          onTap: showResult
                              ? null
                              : () {
                                  setState(() {
                                    selectedAnswer = index;
                                  });
                                },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (!showResult && selectedAnswer != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            provider.answerQuestion(selectedAnswer!);
                            setState(() {
                              showResult = true;
                            });
                          },
                          child: const Text('Antwort prüfen'),
                        ),
                      ),
                    if (showResult) ...[
                      if (provider.hasPrevious)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              provider.previousQuestion();
                              setState(() {
                                selectedAnswer = null;
                                showResult = false;
                              });
                            },
                            child: const Text('Zurück'),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (provider.hasNext)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              provider.nextQuestion();
                              setState(() {
                                selectedAnswer = null;
                                showResult = false;
                              });
                            },
                            child: const Text('Weiter'),
                          ),
                        ),
                      if (!provider.hasNext &&
                          provider.currentSession?.category == 'quick_quiz')
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              _showQuizCompletionDialog(context, provider);
                            },
                            child: const Text('Quiz beenden'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
