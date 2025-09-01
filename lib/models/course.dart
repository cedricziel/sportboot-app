import 'question.dart';

class Course {
  final String name;
  final String version;
  final String source;
  final List<Question> questions;
  final Map<String, dynamic>? metadata;

  const Course({
    required this.name,
    required this.version,
    required this.source,
    required this.questions,
    this.metadata,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      name: map['course'] as String,
      version: map['version'] as String,
      source: map['source'] as String,
      questions: (map['questions'] as List)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'course': name,
      'version': version,
      'source': source,
      'questions': questions.map((q) => q.toMap()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  List<Question> getQuestionsByCategory(String category) {
    return questions.where((q) => q.category == category).toList();
  }

  List<String> get categories {
    return questions.map((q) => q.category).toSet().toList();
  }

  int get totalQuestions => questions.length;
}
