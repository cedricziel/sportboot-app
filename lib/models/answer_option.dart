class AnswerOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;

  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  factory AnswerOption.fromMap(Map<String, dynamic> map) {
    return AnswerOption(
      id: map['id'] as String,
      text: map['text'] as String,
      isCorrect: map['isCorrect'] as bool? ?? false,
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
      if (explanation != null) 'explanation': explanation,
    };
  }
}
