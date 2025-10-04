import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/platform/adaptive_scaffold.dart';
import '../widgets/platform/adaptive_button.dart';
import '../utils/platform_helper.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: const Text('Lernkarten'),
      actions: [
        Consumer<QuestionsProvider>(
          builder: (context, provider, _) {
            return FutureBuilder<bool>(
              future: provider.isCurrentQuestionBookmarked(),
              builder: (context, snapshot) {
                final isBookmarked = snapshot.data ?? false;
                if (PlatformHelper.useIOSStyle) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      isBookmarked
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                    ),
                    onPressed: () {
                      provider.toggleBookmark();
                    },
                  );
                }
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: () {
                    provider.toggleBookmark();
                  },
                );
              },
            );
          },
        ),
      ],
      body: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: PlatformHelper.useIOSStyle
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(),
            );
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
                value: provider.currentQuestions.isNotEmpty
                    ? (provider.currentQuestionIndex + 1) /
                          provider.currentQuestions.length
                    : 0,
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
                    Expanded(
                      child: AdaptiveButton(
                        onPressed: provider.hasPrevious
                            ? () => provider.previousQuestion()
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PlatformHelper.useIOSStyle
                                  ? CupertinoIcons.back
                                  : Icons.arrow_back,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Zurück'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdaptiveButton(
                        onPressed: provider.hasNext
                            ? () => provider.nextQuestion()
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Weiter'),
                            const SizedBox(width: 8),
                            Icon(
                              PlatformHelper.useIOSStyle
                                  ? CupertinoIcons.forward
                                  : Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Session stats
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemGroupedBackground.resolveFrom(
                          context,
                        )
                      : Colors.grey[100],
                  border: PlatformHelper.useIOSStyle
                      ? Border(
                          top: BorderSide(
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Richtig',
                      provider.getSessionStats()['correct'].toString(),
                      PlatformHelper.useIOSStyle
                          ? CupertinoColors.systemGreen
                          : Colors.green,
                    ),
                    _buildStatItem(
                      context,
                      'Falsch',
                      provider.getSessionStats()['incorrect'].toString(),
                      PlatformHelper.useIOSStyle
                          ? CupertinoColors.systemRed
                          : Colors.red,
                    ),
                    _buildStatItem(
                      context,
                      'Offen',
                      provider.getSessionStats()['unanswered'].toString(),
                      PlatformHelper.useIOSStyle
                          ? CupertinoColors.systemOrange
                          : Colors.orange,
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
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
