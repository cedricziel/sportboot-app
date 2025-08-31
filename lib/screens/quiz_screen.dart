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
                                ...question.assets.map((asset) =>
                                  Image.asset(
                                    'assets/images/${asset.split('/').last}',
                                    height: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        color: Colors.grey[200],
                                        child: Text('Bild: ${asset.split('/').last}'),
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
                          onTap: showResult ? null : () {
                            setState(() {
                              selectedAnswer = index;
                            });
                          },
                        );
                      }).toList(),
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