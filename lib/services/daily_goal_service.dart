import '../models/daily_goal.dart';
import '../services/database_helper.dart';
import '../services/storage_service.dart';

class DailyGoalService {
  static const int _defaultDailyTarget = 10;
  static const String _settingKeyDailyTarget = 'dailyGoalTarget';

  final DatabaseHelper _dbHelper;
  final StorageService _storage;

  DailyGoalService({DatabaseHelper? dbHelper, StorageService? storage})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance,
      _storage = storage ?? StorageService();

  /// Get the user's daily question target
  int getDailyTarget() {
    final target = _storage.getSetting(
      _settingKeyDailyTarget,
      defaultValue: _defaultDailyTarget,
    );
    return target is int ? target : _defaultDailyTarget;
  }

  /// Set the user's daily question target
  Future<void> setDailyTarget(int target) async {
    await _storage.setSetting(_settingKeyDailyTarget, target);
  }

  /// Get today's daily goal
  Future<DailyGoal> getTodayGoal() async {
    final today = DailyGoal.getTodayString();
    final db = await _dbHelper.database;

    final results = await db.query(
      DatabaseHelper.tableDailyGoals,
      where: 'date = ?',
      whereArgs: [today],
    );

    if (results.isEmpty) {
      // Create a new goal for today
      final target = getDailyTarget();
      final goal = DailyGoal(
        date: today,
        targetQuestions: target,
        completedQuestions: 0,
      );
      await _insertGoal(goal);
      return goal;
    }

    return DailyGoal.fromMap(results.first);
  }

  /// Increment today's completed question count
  Future<DailyGoal> incrementTodayProgress() async {
    final today = DailyGoal.getTodayString();
    final db = await _dbHelper.database;

    // Get or create today's goal
    final currentGoal = await getTodayGoal();

    final newCompleted = currentGoal.completedQuestions + 1;
    final isNowAchieved = newCompleted >= currentGoal.targetQuestions;
    final wasAlreadyAchieved = currentGoal.isAchieved;

    // Update the goal
    await db.update(
      DatabaseHelper.tableDailyGoals,
      {
        'completed_questions': newCompleted,
        if (isNowAchieved && !wasAlreadyAchieved)
          'achieved_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'date = ?',
      whereArgs: [today],
    );

    // Return the updated goal
    final updatedResults = await db.query(
      DatabaseHelper.tableDailyGoals,
      where: 'date = ?',
      whereArgs: [today],
    );

    return DailyGoal.fromMap(updatedResults.first);
  }

  /// Check if today's goal was just achieved (for showing celebration)
  Future<bool> wasGoalJustAchieved(DailyGoal oldGoal, DailyGoal newGoal) async {
    return !oldGoal.isAchieved && newGoal.isAchieved;
  }

  /// Get the current study streak (consecutive days with achieved goals)
  Future<int> getStreak() async {
    final db = await _dbHelper.database;

    // Get all goals ordered by date descending
    final results = await db.query(
      DatabaseHelper.tableDailyGoals,
      orderBy: 'date DESC',
    );

    if (results.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final row in results) {
      final goal = DailyGoal.fromMap(row);

      // Only count achieved goals
      if (!goal.isAchieved) {
        // If this is today's goal and it's not achieved yet, skip it
        final goalDate = DateTime.parse(goal.date);
        final today = DateTime.now();
        if (goalDate.year == today.year &&
            goalDate.month == today.month &&
            goalDate.day == today.day) {
          continue;
        }
        break; // Streak is broken
      }

      final goalDate = DateTime.parse(goal.date);

      if (lastDate == null) {
        // First achieved goal
        lastDate = goalDate;
        streak = 1;
      } else {
        // Check if this is the previous day
        final expectedPrevious = lastDate.subtract(const Duration(days: 1));
        if (goalDate.year == expectedPrevious.year &&
            goalDate.month == expectedPrevious.month &&
            goalDate.day == expectedPrevious.day) {
          streak++;
          lastDate = goalDate;
        } else {
          break; // Streak is broken
        }
      }
    }

    return streak;
  }

  /// Get daily goals for a date range
  Future<List<DailyGoal>> getGoalsInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = DailyGoal.getDateString(start);
    final endStr = DailyGoal.getDateString(end);

    final results = await db.query(
      DatabaseHelper.tableDailyGoals,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );

    return results.map((row) => DailyGoal.fromMap(row)).toList();
  }

  /// Get all goals (for statistics/history)
  Future<List<DailyGoal>> getAllGoals() async {
    final db = await _dbHelper.database;

    final results = await db.query(
      DatabaseHelper.tableDailyGoals,
      orderBy: 'date DESC',
    );

    return results.map((row) => DailyGoal.fromMap(row)).toList();
  }

  /// Get the total number of days with achieved goals
  Future<int> getTotalDaysAchieved() async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM ${DatabaseHelper.tableDailyGoals}
      WHERE completed_questions >= target_questions
      ''');

    return (results.first['count'] as int?) ?? 0;
  }

  /// Insert a new goal
  Future<void> _insertGoal(DailyGoal goal) async {
    final db = await _dbHelper.database;
    await db.insert(DatabaseHelper.tableDailyGoals, goal.toMap());
  }

  /// Reset all goals (for testing or user request)
  Future<void> resetAllGoals() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableDailyGoals);
  }

  /// Check if daily goals are enabled
  bool areGoalsEnabled() {
    return _storage.getSetting('dailyGoalsEnabled', defaultValue: true);
  }

  /// Enable or disable daily goals
  Future<void> setGoalsEnabled(bool enabled) async {
    await _storage.setSetting('dailyGoalsEnabled', enabled);
  }

  /// Get motivational messages for celebrations
  List<String> getMotivationalMessages() {
    return [
      'Fantastisch! Tagesziel erreicht! 🎉',
      'Großartig! Du bleibst am Ball! 🚀',
      'Super! Weiter so! ⭐',
      'Exzellent! Du machst Fortschritte! 💪',
      'Klasse! Ziel für heute erreicht! 🎯',
      'Bravo! Du bist auf Kurs! 🌟',
      'Toll! Deine Disziplin zahlt sich aus! 🏆',
    ];
  }

  /// Get a random motivational message
  String getRandomMotivationalMessage() {
    final messages = getMotivationalMessages();
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }
}
