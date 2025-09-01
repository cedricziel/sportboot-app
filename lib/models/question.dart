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
    return Question(
      id: map['id'] as String,
      number: map['number'] as int,
      question: map['question'] as String,
      options: (map['options'] as List)
          .map((option) => AnswerOption.fromMap(option as Map<String, dynamic>))
          .toList(),
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
}
