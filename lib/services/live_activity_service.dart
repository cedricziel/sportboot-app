import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

import '../models/daily_goal.dart';

class LiveActivityService {
  final LiveActivities _liveActivities = LiveActivities();
  String? _currentActivityId;
  bool _isInitialized = false;
  static const String _appGroupId = 'group.com.cedricziel.sportbootApp';

  /// Initialize the Live Activities plugin
  Future<void> init() async {
    if (_isInitialized) return;

    // Only available on iOS (check web first to avoid Platform access on web)
    if (kIsWeb || !Platform.isIOS) {
      _isInitialized = true;
      return;
    }

    try {
      await _liveActivities.init(appGroupId: _appGroupId);
      _isInitialized = true;
      debugPrint('[LiveActivity] Initialized with App Group: $_appGroupId');
    } catch (e) {
      debugPrint('[LiveActivity] Error initializing: $e');
    }
  }

  /// Start a Live Activity for study session
  Future<void> startLiveActivity({
    required String courseName,
    required int targetQuestions,
    required int currentStreak,
  }) async {
    // Ensure initialized
    await init();

    // Only available on iOS (check web first to avoid Platform access on web)
    if (kIsWeb || !Platform.isIOS) {
      return;
    }

    try {
      // Check if Live Activities are enabled
      final areEnabled = await _liveActivities.areActivitiesEnabled();
      if (!areEnabled) {
        debugPrint('[LiveActivity] Live Activities not enabled');
        return;
      }

      // End any existing activity first
      if (_currentActivityId != null) {
        await endLiveActivity();
      }

      // Create activity data - combine all data into one map
      final activityData = {
        'courseName': courseName,
        'questionsCompleted': 0,
        'targetQuestions': targetQuestions,
        'currentStreak': currentStreak,
        'isGoalAchieved': false,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Generate a unique activity ID
      final activityId =
          'sportboot_quiz_${DateTime.now().millisecondsSinceEpoch}';

      // Start the Live Activity with explicit ID
      _currentActivityId = await _liveActivities.createActivity(
        activityId,
        activityData,
      );

      debugPrint('[LiveActivity] Started activity: $_currentActivityId');
    } catch (e) {
      debugPrint('[LiveActivity] Error starting activity: $e');
    }
  }

  /// Update Live Activity progress
  Future<void> updateLiveActivity({
    required int questionsCompleted,
    required int targetQuestions,
    required int currentStreak,
    required bool isGoalAchieved,
  }) async {
    if (_currentActivityId == null) {
      debugPrint('[LiveActivity] No active activity to update');
      return;
    }

    try {
      final contentState = {
        'questionsCompleted': questionsCompleted,
        'targetQuestions': targetQuestions,
        'currentStreak': currentStreak,
        'isGoalAchieved': isGoalAchieved,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _liveActivities.updateActivity(_currentActivityId!, contentState);

      debugPrint(
        '[LiveActivity] Updated: $questionsCompleted/$targetQuestions (streak: $currentStreak)',
      );
    } catch (e) {
      debugPrint('[LiveActivity] Error updating activity: $e');
    }
  }

  /// Update Live Activity with DailyGoal data
  Future<void> updateFromDailyGoal({
    required DailyGoal goal,
    required int currentStreak,
  }) async {
    await updateLiveActivity(
      questionsCompleted: goal.completedQuestions,
      targetQuestions: goal.targetQuestions,
      currentStreak: currentStreak,
      isGoalAchieved: goal.isAchieved,
    );
  }

  /// End the current Live Activity
  Future<void> endLiveActivity() async {
    if (_currentActivityId == null) {
      return;
    }

    try {
      await _liveActivities.endActivity(_currentActivityId!);
      debugPrint('[LiveActivity] Ended activity: $_currentActivityId');
      _currentActivityId = null;
    } catch (e) {
      debugPrint('[LiveActivity] Error ending activity: $e');
    }
  }

  /// End activity with final state (e.g., when goal is achieved)
  Future<void> endActivityWithFinalState({
    required int questionsCompleted,
    required int targetQuestions,
    required int currentStreak,
    required bool isGoalAchieved,
  }) async {
    if (_currentActivityId == null) {
      return;
    }

    try {
      // Update with final state before ending
      await updateLiveActivity(
        questionsCompleted: questionsCompleted,
        targetQuestions: targetQuestions,
        currentStreak: currentStreak,
        isGoalAchieved: isGoalAchieved,
      );

      // End the activity
      await _liveActivities.endActivity(_currentActivityId!);

      debugPrint(
        '[LiveActivity] Ended with final state: $questionsCompleted/$targetQuestions',
      );
      _currentActivityId = null;
    } catch (e) {
      debugPrint('[LiveActivity] Error ending activity with state: $e');
    }
  }

  /// Check if Live Activities are currently active
  bool get hasActiveActivity => _currentActivityId != null;

  /// Get all active Live Activities
  Future<List<String>> getActiveActivities() async {
    try {
      return await _liveActivities.getAllActivitiesIds();
    } catch (e) {
      debugPrint('[LiveActivity] Error getting activities: $e');
      return [];
    }
  }

  /// End all Live Activities (cleanup)
  Future<void> endAllActivities() async {
    try {
      final activities = await getActiveActivities();
      for (final activityId in activities) {
        await _liveActivities.endActivity(activityId);
      }
      _currentActivityId = null;
      debugPrint('[LiveActivity] Ended all activities');
    } catch (e) {
      debugPrint('[LiveActivity] Error ending all activities: $e');
    }
  }

  /// Check if Live Activities are enabled on device
  Future<bool> areActivitiesEnabled() async {
    try {
      return await _liveActivities.areActivitiesEnabled();
    } catch (e) {
      debugPrint('[LiveActivity] Error checking if enabled: $e');
      return false;
    }
  }
}
