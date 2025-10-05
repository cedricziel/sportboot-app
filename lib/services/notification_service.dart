import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  static const String _channelId = 'daily_quiz_reminder';
  static const String _channelName = 'Tägliche Quiz-Erinnerung';
  static const String _channelDescription =
      'Erinnert dich täglich daran, dein Quiz zu machen';

  // Notification IDs
  static const int _dailyNotificationId = 1;

  // Motivational messages for notifications
  static final List<String> _notificationMessages = [
    'Zeit für dein tägliches Quiz! 🚤',
    'Bereit für 5 Minuten Lernen? 💪',
    'Dein Sportbootführerschein wartet auf dich!',
    'Komm, lass uns ein paar Fragen üben! 📚',
    'Halte deinen Lernstreak aufrecht! 🔥',
    'Zeit, dein Wissen zu testen! 🎯',
    'Ein kurzes Quiz hält dich auf Kurs! ⛵',
    'Nur ein paar Fragen heute! 🌊',
    'Bleib dran - du schaffst das! 💯',
    'Dein tägliches Lernziel wartet! 🎓',
  ];

  Future<void> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Initialize plugin
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings, // Use same Darwin settings for macOS
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create notification channel for Android
      await _createNotificationChannel();
    } catch (e) {
      // Silently fail in test environment
      debugPrint('NotificationService init failed (likely in test): $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    // macOS - use plugin directly
    if (Platform.isMacOS) {
      final macOS = _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macOS != null) {
        final granted = await macOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true; // Assume granted if we can't check
    }

    // iOS - use ONLY the plugin (not permission_handler)
    if (Platform.isIOS) {
      final iOS = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iOS != null) {
        final granted = await iOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    }

    // Android - use permission_handler for Android 13+ POST_NOTIFICATIONS
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    // macOS and iOS don't provide a reliable way to check notification status
    // via the plugin, so we use stored settings
    if (Platform.isMacOS || Platform.isIOS) {
      // For macOS/iOS, we can't easily check if notifications are enabled
      // Return the stored setting instead
      return _storage.getSetting('notificationsEnabled', defaultValue: false);
    }

    // Android - check actual permission status
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Schedule daily notification at specific time
  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    try {
      // Cancel existing notifications first
      await cancelAllNotifications();

      // Check permissions
      final hasPermission = await areNotificationsEnabled();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return;
      }

      // Get current date
      final now = tz.TZDateTime.now(tz.local);

      // Create scheduled time for today
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Get random motivational message
      final random = Random();
      final message =
          _notificationMessages[random.nextInt(_notificationMessages.length)];

      // Get course name from storage
      final selectedCourse = _storage.getSetting(
        'selectedCourseId',
        defaultValue: 'SBF-See',
      );
      final courseNames = {
        'sbf-see': 'SBF-See',
        'sbf-binnen': 'SBF-Binnen',
        'sbf-binnen-segeln': 'SBF-Binnen Segeln',
      };
      final courseName = courseNames[selectedCourse] ?? 'Sportbootführerschein';

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Quiz-Erinnerung',
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: 'Zeit zum Lernen! 📚',
          summaryText: courseName,
        ),
        actions: [
          const AndroidNotificationAction(
            'start_quiz',
            'Quiz starten',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction('later', 'Später'),
        ],
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'quiz_reminder',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        _dailyNotificationId,
        'Zeit zum Lernen! 📚',
        message,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at same time
        payload: 'open_quiz',
      );

      // Save notification settings
      await _storage.setSetting('notificationsEnabled', true);
      await _storage.setSetting(
        'notificationTime',
        '${time.hour}:${time.minute}',
      );
    } catch (e) {
      debugPrint('scheduleDailyNotification failed (likely in test): $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      await _storage.setSetting('notificationsEnabled', false);
    } catch (e) {
      debugPrint('cancelAllNotifications failed (likely in test): $e');
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('cancelNotification failed (likely in test): $e');
    }
  }

  // Show instant notification (for preview)
  Future<void> showTestNotification() async {
    try {
      final random = Random();
      final message =
          _notificationMessages[random.nextInt(_notificationMessages.length)];

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Test-Benachrichtigung',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _notifications.show(
        999, // Different ID for test notification
        'Zeit zum Lernen! 📚',
        message,
        notificationDetails,
        payload: 'test',
      );
    } catch (e) {
      debugPrint('showTestNotification failed (likely in test): $e');
    }
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == 'open_quiz' || response.actionId == 'start_quiz') {
      // Navigate to quiz screen
      // This will be handled in main.dart where we have access to NavigatorKey
      _notificationTapCallback?.call();
    }
  }

  // Callback for handling notification taps
  Function()? _notificationTapCallback;

  void setNotificationTapCallback(Function() callback) {
    _notificationTapCallback = callback;
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('getPendingNotifications failed (likely in test): $e');
      return [];
    }
  }

  // Check if daily notification is scheduled
  Future<bool> isDailyNotificationScheduled() async {
    try {
      final pending = await getPendingNotifications();
      return pending.any(
        (notification) => notification.id == _dailyNotificationId,
      );
    } catch (e) {
      debugPrint('isDailyNotificationScheduled failed (likely in test): $e');
      return false;
    }
  }

  // Update notification time (reschedule)
  Future<void> updateNotificationTime(TimeOfDay newTime) async {
    final isEnabled = _storage.getSetting(
      'notificationsEnabled',
      defaultValue: false,
    );
    if (isEnabled) {
      await scheduleDailyNotification(newTime);
    }
  }

  // Get statistics about notification engagement
  Map<String, dynamic> getNotificationStats() {
    return {
      'enabled': _storage.getSetting(
        'notificationsEnabled',
        defaultValue: false,
      ),
      'time': _storage.getSetting('notificationTime', defaultValue: '19:00'),
      'lastShown': _storage.getSetting('lastNotificationDate'),
      'interactionCount': _storage.getSetting(
        'notificationInteractions',
        defaultValue: 0,
      ),
    };
  }

  // Track notification interaction
  void trackNotificationInteraction() {
    final currentCount =
        _storage.getSetting('notificationInteractions', defaultValue: 0) as int;
    _storage.setSetting('notificationInteractions', currentCount + 1);
    _storage.setSetting(
      'lastNotificationInteraction',
      DateTime.now().toIso8601String(),
    );
  }
}
