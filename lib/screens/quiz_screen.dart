import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../providers/questions_provider.dart';
import '../router/app_router.dart';
import '../widgets/answer_option_widget.dart';
import '../widgets/zoomable_image.dart';
import '../widgets/platform/adaptive_card.dart';

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
  ) async {
    final stats = provider.getSessionStats();
    final totalQuestions = provider.currentQuestions.length;
    final correctAnswers = stats['correct'] ?? 0;
    final incorrectAnswers = stats['incorrect'] ?? 0;
    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;

    await provider.endSession();

    if (!context.mounted) return;

    showPlatformDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlatformAlertDialog(
        title: const Text('Quiz beendet!'),
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
                  isCupertino(context)
                      ? CupertinoColors.systemGreen
                      : Colors.green,
                ),
                _buildStatItem(
                  'Falsch',
                  incorrectAnswers.toString(),
                  isCupertino(context) ? CupertinoColors.systemRed : Colors.red,
                ),
                _buildStatItem(
                  'Prozent',
                  '$percentage%',
                  isCupertino(context)
                      ? CupertinoColors.systemBlue
                      : Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: correctAnswers / totalQuestions,
              backgroundColor: isCupertino(context)
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 80
                    ? (isCupertino(context)
                          ? CupertinoColors.systemGreen
                          : Colors.green)
                    : percentage >= 60
                    ? (isCupertino(context)
                          ? CupertinoColors.systemOrange
                          : Colors.orange)
                    : (isCupertino(context)
                          ? CupertinoColors.systemRed
                          : Colors.red),
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
          PlatformDialogAction(
            onPressed: () async {
              context.pop(); // Close dialog
              context.pop(); // Go back to home

              // Start a new quick quiz
              final newProvider = context.read<QuestionsProvider>();
              await newProvider.loadRandomQuestions(14);
              await newProvider.startSession('quiz', 'quick_quiz');

              if (context.mounted) {
                context.push(AppRoutes.quiz);
              }
            },
            child: const Text('Neues Quiz'),
          ),
          PlatformDialogAction(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Go back to home
            },
            child: const Text('Zurück zum Menü'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final subtitleColor = isCupertino(context)
        ? CupertinoColors.secondaryLabel
        : Colors.grey[600];

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
        Text(label, style: TextStyle(fontSize: 12, color: subtitleColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: const PlatformAppBar(title: Text('Quiz-Modus')),
      body: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: PlatformCircularProgressIndicator());
          }

          // Show error if present
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    PlatformElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Zurück'),
                    ),
                  ],
                ),
              ),
            );
          }

          final question = provider.currentQuestion;
          if (question == null) {
            // Show debug info to understand why questions are not available
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Keine Fragen verfügbar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Geladene Fragen: ${provider.currentQuestions.length}',
                    ),
                    Text('Aktueller Index: ${provider.currentQuestionIndex}'),
                    Text('Session aktiv: ${provider.currentSession != null}'),
                    if (provider.currentSession != null) ...[
                      Text(
                        'Session Kategorie: ${provider.currentSession!.category}',
                      ),
                      Text(
                        'Session Fragen: ${provider.currentSession!.questionIds.length}',
                      ),
                    ],
                    const SizedBox(height: 24),
                    PlatformElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Zurück'),
                    ),
                  ],
                ),
              ),
            );
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
                  style: TextStyle(
                    fontSize: 16,
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdaptiveCard(
                        child: Column(
                          children: [
                            SelectableText(
                              _removeSquareBrackets(question.question),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                                color: isCupertino(context)
                                    ? CupertinoColors.label.resolveFrom(context)
                                    : null,
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
                        child: PlatformElevatedButton(
                          onPressed: () async {
                            await provider.answerQuestion(selectedAnswer!);

                            if (!mounted) return;

                            setState(() {
                              showResult = true;
                            });

                            // Check if daily goal was just achieved
                            if (provider.shouldShowCelebration) {
                              provider.markCelebrationShown();
                              final streak = await provider.getStreak();

                              if (!mounted) return;

                              final todayGoal = provider.todayGoal;
                              if (todayGoal != null && context.mounted) {
                                context.push(
                                  AppRoutes.goalAchieved,
                                  extra: {
                                    'streak': streak,
                                    'questionsCompleted':
                                        todayGoal.completedQuestions,
                                    'message': 'Tagesziel erreicht! 🎉',
                                  },
                                );
                              }
                            }
                          },
                          child: const Text('Antwort prüfen'),
                        ),
                      ),
                    if (showResult) ...[
                      if (provider.hasPrevious)
                        Expanded(
                          child: PlatformElevatedButton(
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
                          child: PlatformElevatedButton(
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
                          provider.currentSession?.mode == 'quiz')
                        Expanded(
                          child: PlatformElevatedButton(
                            onPressed: () {
                              _showQuizCompletionDialog(context, provider);
                            },
                            material: (context, platform) =>
                                MaterialElevatedButtonData(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
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
