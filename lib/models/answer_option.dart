class AnswerOption {
  final String text;
  final bool isCorrect;
  final String? explanation;

  const AnswerOption({
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  factory AnswerOption.fromMap(Map<String, dynamic> map) {
    return AnswerOption(
      text: map['text'] as String,
      isCorrect: map['isCorrect'] as bool? ?? false,
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      if (explanation != null) 'explanation': explanation,
    };
  }
}
