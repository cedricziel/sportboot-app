import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';

class StorageService {
  static const String _progressKey = 'study_progress';
  static const String _sessionsKey = 'study_sessions';
  static const String _bookmarksKey = 'bookmarked_questions';
  static const String _settingsKey = 'app_settings';

  late final SharedPreferences _prefs;
  bool _isInitialized = false;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> init() async {
    if (_isInitialized) return; // Skip if already initialized
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // Study Progress Management
  Future<void> saveQuestionProgress(
    String questionId,
    bool isCorrect,
    int attempts,
  ) async {
    final progress = getProgress();
    progress[questionId] = {
      'correct': isCorrect,
      'attempts': attempts,
      'lastStudied': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_progressKey, jsonEncode(progress));
  }

  Map<String, dynamic> getProgress() {
    final String? progressJson = _prefs.getString(_progressKey);
    if (progressJson == null) return {};
    return jsonDecode(progressJson) as Map<String, dynamic>;
  }

  Future<void> clearProgress() async {
    await _prefs.remove(_progressKey);
  }

  // Bookmark Management
  Future<void> toggleBookmark(String questionId) async {
    final bookmarks = getBookmarks();
    if (bookmarks.contains(questionId)) {
      bookmarks.remove(questionId);
    } else {
      bookmarks.add(questionId);
    }
    await _prefs.setStringList(_bookmarksKey, bookmarks);
  }

  List<String> getBookmarks() {
    return _prefs.getStringList(_bookmarksKey) ?? [];
  }

  bool isBookmarked(String questionId) {
    return getBookmarks().contains(questionId);
  }

  // Settings Management
  Future<void> saveSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic> getSettings() {
    final String? settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson == null) {
      // Return default settings
      return {
        'shuffleQuestions': false,
        'showTimer': true,
        'soundEnabled': true,
        'dailyGoal': 20,
        'theme': 'light',
      };
    }
    return jsonDecode(settingsJson) as Map<String, dynamic>;
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    final settings = getSettings();
    return settings[key] ?? defaultValue;
  }

  Future<void> setSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  // Statistics
  Future<void> incrementStatistic(String key) async {
    final current = _prefs.getInt('stat_$key') ?? 0;
    await _prefs.setInt('stat_$key', current + 1);
  }

  int getStatistic(String key) {
    return _prefs.getInt('stat_$key') ?? 0;
  }

  Map<String, int> getAllStatistics() {
    return {
      'totalQuestions': getStatistic('totalQuestions'),
      'correctAnswers': getStatistic('correctAnswers'),
      'incorrectAnswers': getStatistic('incorrectAnswers'),
      'studySessions': getStatistic('studySessions'),
      'totalTimeSpent': getStatistic('totalTimeSpent'),
    };
  }

  // Study Streak
  Future<void> updateStudyStreak() async {
    final lastStudy = _prefs.getString('lastStudyDate');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastStudy == null) {
      await _prefs.setInt('studyStreak', 1);
    } else {
      final lastDate = DateTime.parse(lastStudy);
      final difference = DateTime.now().difference(lastDate).inDays;

      if (difference == 1) {
        final streak = _prefs.getInt('studyStreak') ?? 0;
        await _prefs.setInt('studyStreak', streak + 1);
      } else if (difference > 1) {
        await _prefs.setInt('studyStreak', 1);
      }
    }

    await _prefs.setString('lastStudyDate', today);
  }

  int getStudyStreak() {
    return _prefs.getInt('studyStreak') ?? 0;
  }
}
