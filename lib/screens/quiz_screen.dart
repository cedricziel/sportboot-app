import 'package:flutter/material.dart' hide showAdaptiveDialog;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../router/app_router.dart';
import '../widgets/answer_option_widget.dart';
import '../widgets/zoomable_image.dart';
import '../widgets/platform/adaptive_scaffold.dart';
import '../widgets/platform/adaptive_dialog.dart';
import '../widgets/platform/adaptive_button.dart';
import '../utils/platform_helper.dart';

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

    showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      title: 'Quiz beendet!',
      contentWidget: Column(
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
              _buildStatItem('Falsch', incorrectAnswers.toString(), Colors.red),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        AdaptiveDialogAction(
          onPressed: () async {
            context.pop(); // Close dialog
            context.pop(); // Go back to home

            // Start a new quick quiz
            final newProvider = context.read<QuestionsProvider>();
            await newProvider.loadRandomQuestions(14);
            newProvider.startSession('quiz', 'quick_quiz');

            if (context.mounted) {
              context.push(AppRoutes.quiz);
            }
          },
          child: const Text('Neues Quiz'),
        ),
        AdaptiveDialogAction(
          onPressed: () {
            context.pop(); // Close dialog
            context.pop(); // Go back to home
          },
          isDefault: true,
          child: const Text('Zurück zum Menü'),
        ),
      ],
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
    return AdaptiveScaffold(
      title: const Text('Quiz-Modus'),
      body: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: PlatformHelper.useIOSStyle
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(),
            );
          }

          final question = provider.currentQuestion;
          if (question == null) {
            return const Center(child: Text('Keine Fragen verfügbar'));
          }

          return Column(
            children: [
              LinearProgressIndicator(
                value: provider.currentQuestions.isNotEmpty
                    ? (provider.currentQuestionIndex + 1) /
                          provider.currentQuestions.length
                    : 0,
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
                              SelectableText(
                                _removeSquareBrackets(question.question),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (question.assets.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ...question.assets.map(
                                  (asset) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.25,
                                        maxWidth:
                                            MediaQuery.of(context).size.width -
                                            48,
                                      ),
                                      child: ZoomableImage(
                                        assetPath:
                                            'assets/images/${asset.split('/').last}',
                                        height: 150,
                                      ),
                                    ),
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
                        child: AdaptiveButton(
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
                          child: AdaptiveButton(
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
                          child: AdaptiveButton(
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
                          child: AdaptiveButton(
                            onPressed: () {
                              _showQuizCompletionDialog(context, provider);
                            },
                            color: Colors.green,
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

  // Helper function to remove square bracketed descriptions from text
  String _removeSquareBrackets(String text) {
    // Remove all text within square brackets including the brackets
    return text.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
  }
}
