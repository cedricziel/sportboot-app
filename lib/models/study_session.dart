import 'question.dart';

class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> questionIds;
  final Map<String, bool> answers; // questionId -> isCorrect
  final Map<String, int> timeSpent; // questionId -> seconds
  final String category;
  final String mode; // 'flashcard' or 'quiz'

  StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.questionIds,
    required this.answers,
    required this.timeSpent,
    required this.category,
    required this.mode,
  });

  int get totalQuestions => questionIds.length;
  
  int get correctAnswers => 
      answers.values.where((isCorrect) => isCorrect).length;
  
  int get incorrectAnswers => 
      answers.values.where((isCorrect) => !isCorrect).length;
  
  int get unanswered => 
      totalQuestions - answers.length;
  
  double get accuracy => 
      answers.isEmpty ? 0 : (correctAnswers / answers.length) * 100;
  
  int get totalTimeSpent => 
      timeSpent.values.fold(0, (sum, time) => sum + time);
  
  Duration get sessionDuration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  bool isQuestionAnswered(String questionId) {
    return answers.containsKey(questionId);
  }

  bool? getAnswer(String questionId) {
    return answers[questionId];
  }

  StudySession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? questionIds,
    Map<String, bool>? answers,
    Map<String, int>? timeSpent,
    String? category,
    String? mode,
  }) {
    return StudySession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionIds: questionIds ?? this.questionIds,
      answers: answers ?? this.answers,
      timeSpent: timeSpent ?? this.timeSpent,
      category: category ?? this.category,
      mode: mode ?? this.mode,
    );
  }
}