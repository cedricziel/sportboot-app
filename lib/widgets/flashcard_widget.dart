import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flip_card/flip_card.dart';
import '../models/question.dart';
import 'zoomable_image.dart';
import '../utils/platform_helper.dart';

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

  Widget _buildCard(BuildContext context, Widget content, Color cardColor) {
    if (PlatformHelper.useIOSStyle) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      ),
    );
  }

  Widget _buildQuestionSide(BuildContext context) {
    // Remove bracketed descriptions from question text
    final cleanedQuestion = _removeSquareBrackets(question.question);
    final iconColor = PlatformHelper.useIOSStyle
        ? CupertinoColors.systemBlue
        : Colors.blue;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformHelper.useIOSStyle
                  ? CupertinoIcons.question_circle
                  : Icons.help_outline,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            SelectableText(
              cleanedQuestion,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            if (question.assets.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...question.assets.map(
                (asset) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                      maxWidth: MediaQuery.of(context).size.width - 48,
                    ),
                    child: ZoomableImage(
                      assetPath: 'assets/images/${asset.split('/').last}',
                      height: 150,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Tippe zum Umdrehen',
              style: TextStyle(
                color: PlatformHelper.useIOSStyle
                    ? CupertinoColors.secondaryLabel
                    : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSide(BuildContext context) {
    final iconColor = PlatformHelper.useIOSStyle
        ? CupertinoColors.systemGreen
        : Colors.green;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformHelper.useIOSStyle
                  ? CupertinoIcons.lightbulb
                  : Icons.lightbulb_outline,
              size: 48,
              color: iconColor,
            ),
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

              final correctColor = PlatformHelper.useIOSStyle
                  ? CupertinoColors.systemGreen
                  : Colors.green;
              final correctBg = PlatformHelper.useIOSStyle
                  ? CupertinoColors.systemGreen.withOpacity(0.1)
                  : Colors.green.shade100;
              final defaultBg = PlatformHelper.useIOSStyle
                  ? CupertinoColors.systemBackground.resolveFrom(context)
                  : Colors.white;
              final defaultBorder = PlatformHelper.useIOSStyle
                  ? CupertinoColors.separator.resolveFrom(context)
                  : Colors.grey.shade300;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: option.isCorrect ? correctBg : defaultBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: option.isCorrect ? correctColor : defaultBorder,
                    width: option.isCorrect ? 2 : 0.5,
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
                            ? correctColor
                            : (PlatformHelper.useIOSStyle
                                  ? CupertinoColors.systemGrey
                                  : Colors.grey.shade400),
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
                          SelectableText(
                            option.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: option.isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          if (option.isCorrect) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  PlatformHelper.useIOSStyle
                                      ? CupertinoIcons.check_mark_circled_solid
                                      : Icons.check_circle,
                                  size: 16,
                                  color: correctColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Richtige Antwort',
                                  style: TextStyle(
                                    color: correctColor,
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
            }),
            if (question.explanation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PlatformHelper.useIOSStyle
                      ? CupertinoColors.systemBlue.withOpacity(0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformHelper.useIOSStyle
                              ? CupertinoIcons.info_circle
                              : Icons.info_outline,
                          size: 20,
                          color: PlatformHelper.useIOSStyle
                              ? CupertinoColors.systemBlue
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Erklärung:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: PlatformHelper.useIOSStyle
                                ? CupertinoColors.systemBlue
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      question.explanation!,
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
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

  // Helper function to remove square bracketed descriptions from text
  String _removeSquareBrackets(String text) {
    // Remove all text within square brackets including the brackets
    return text.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
  }
}
