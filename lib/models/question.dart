import 'dart:math';
import 'answer_option.dart';

class Question {
  final String id;
  final int number;
  final String question;
  final List<AnswerOption> options;
  final String category;
  final List<String> assets;
  final String? subcategory;
  final String? difficulty;
  final List<String>? tags;
  final String? explanation;

  const Question({
    required this.id,
    required this.number,
    required this.question,
    required this.options,
    required this.category,
    required this.assets,
    this.subcategory,
    this.difficulty,
    this.tags,
    this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    // Handle both 'options' (new format) and 'answers' (legacy format)
    List<AnswerOption> options;

    if (map.containsKey('options')) {
      // New format with structured options
      final optionsList = map['options'] as List;
      options = [];
      for (int i = 0; i < optionsList.length; i++) {
        final optionMap = Map<String, dynamic>.from(
          optionsList[i] as Map<String, dynamic>,
        );
        // Generate ID if missing
        if (!optionMap.containsKey('id') || optionMap['id'] == null) {
          optionMap['id'] = 'a_${map['id']}_$i';
        }
        options.add(AnswerOption.fromMap(optionMap));
      }
    } else if (map.containsKey('answers')) {
      // Legacy format with simple string answers
      // Generate IDs for backward compatibility
      final answers = map['answers'] as List;
      options = [];
      for (int i = 0; i < answers.length; i++) {
        // Generate a simple ID based on question ID and index
        final answerId = 'a_legacy_${map['id']}_$i';
        options.add(
          AnswerOption(
            id: answerId,
            text: answers[i] as String,
            isCorrect:
                i == 0, // Assume first answer is correct for legacy format
          ),
        );
      }
    } else {
      options = [];
    }

    return Question(
      id: map['id'] as String,
      number: map['number'] as int,
      question:
          map['question'] as String? ??
          map['text'] as String, // Support both 'question' and 'text' fields
      options: options,
      category: map['category'] as String,
      assets: (map['assets'] as List?)?.cast<String>() ?? [],
      subcategory: map['subcategory'] as String?,
      difficulty: map['difficulty'] as String?,
      tags: (map['tags'] as List?)?.cast<String>(),
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'question': question,
      'options': options.map((option) => option.toMap()).toList(),
      'category': category,
      'assets': assets,
      if (subcategory != null) 'subcategory': subcategory,
      if (difficulty != null) 'difficulty': difficulty,
      if (tags != null) 'tags': tags,
      if (explanation != null) 'explanation': explanation,
    };
  }

  AnswerOption? get correctAnswer {
    try {
      return options.firstWhere((option) => option.isCorrect);
    } catch (_) {
      return null;
    }
  }

  bool isAnswerCorrect(int index) {
    if (index < 0 || index >= options.length) return false;
    return options[index].isCorrect;
  }

  // Create a copy of the question with shuffled answer options
  Question copyWithShuffledOptions() {
    final random = Random();
    final shuffledOptions = List<AnswerOption>.from(options)..shuffle(random);

    return Question(
      id: id,
      number: number,
      question: question,
      options: shuffledOptions,
      category: category,
      assets: assets,
      subcategory: subcategory,
      difficulty: difficulty,
      tags: tags,
      explanation: explanation,
    );
  }
}
