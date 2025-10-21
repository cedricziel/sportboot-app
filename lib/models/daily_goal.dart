class DailyGoal {
  final String date; // Format: YYYY-MM-DD
  final int targetQuestions;
  final int completedQuestions;
  final bool isAchieved;
  final DateTime? achievedAt;

  DailyGoal({
    required this.date,
    required this.targetQuestions,
    required this.completedQuestions,
    this.achievedAt,
  }) : isAchieved = completedQuestions >= targetQuestions;

  double get progress =>
      targetQuestions > 0 ? (completedQuestions / targetQuestions) : 0.0;

  bool get isToday {
    final today = DateTime.now();
    final goalDate = DateTime.parse(date);
    return goalDate.year == today.year &&
        goalDate.month == today.month &&
        goalDate.day == today.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'target_questions': targetQuestions,
      'completed_questions': completedQuestions,
      'achieved_at': achievedAt?.millisecondsSinceEpoch,
    };
  }

  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      date: map['date'] as String,
      targetQuestions: map['target_questions'] as int,
      completedQuestions: map['completed_questions'] as int,
      achievedAt: map['achieved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['achieved_at'] as int)
          : null,
    );
  }

  DailyGoal copyWith({
    String? date,
    int? targetQuestions,
    int? completedQuestions,
    DateTime? achievedAt,
  }) {
    return DailyGoal(
      date: date ?? this.date,
      targetQuestions: targetQuestions ?? this.targetQuestions,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  static String getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String getTodayString() {
    return getDateString(DateTime.now());
  }
}
