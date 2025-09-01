import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../models/question.dart';

class FlashcardWidget extends StatelessWidget {
  final Question question;
  final VoidCallback? onFlip;

  const FlashcardWidget({super.key, required this.question, this.onFlip});

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      onFlip: onFlip,
      front: _buildCard(
        context,
        _buildQuestionSide(context),
        Colors.blue.shade50,
      ),
      back: _buildCard(
        context,
        _buildAnswerSide(context),
        Colors.green.shade50,
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget content, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      ),
    );
  }

  Widget _buildQuestionSide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.help_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (question.assets.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...question.assets.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.asset(
                      'assets/images/${asset.split('/').last}',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[200],
                          child: Text(
                            'Bild: ${asset.split('/').last}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Text(
                'Tippe zum Umdrehen',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSide(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 48, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Antwortmöglichkeiten:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final letter = String.fromCharCode(97 + index); // a, b, c, d

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: option.isCorrect
                      ? Colors.green.shade100
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: option.isCorrect
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: option.isCorrect ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: option.isCorrect
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                      child: Center(
                        child: Text(
                          letter.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: option.isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (option.isCorrect) ...[
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Richtige Antwort',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (question.explanation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Erklärung:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
