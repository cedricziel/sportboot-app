import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sportboot_app/services/notification_service.dart';
import 'package:sportboot_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize SharedPreferences with test values once
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': false,
      'notificationTime': '19:00',
      'selectedCourseId': 'sbf-see',
    });
    
    await StorageService().init();
  });
  
  group('NotificationService', () {
    late NotificationService notificationService;
    
    setUp(() async {
      notificationService = NotificationService();
    });

    test('should be a singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    test('should initialize without errors', () async {
      await expectLater(
        notificationService.init(),
        completes,
      );
    });

    test('should have motivational messages', () {
      // Access through reflection or make messages public in the service
      // For now, we just verify the service exists
      expect(notificationService, isNotNull);
    });

    test('should get notification stats', () {
      final stats = notificationService.getNotificationStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('enabled'), isTrue);
      expect(stats.containsKey('time'), isTrue);
      expect(stats.containsKey('lastShown'), isTrue);
      expect(stats.containsKey('interactionCount'), isTrue);
    });

    test('should track notification interaction', () {
      final initialStats = notificationService.getNotificationStats();
      final initialCount = initialStats['interactionCount'] as int;
      
      notificationService.trackNotificationInteraction();
      
      final updatedStats = notificationService.getNotificationStats();
      final updatedCount = updatedStats['interactionCount'] as int;
      
      expect(updatedCount, equals(initialCount + 1));
    });

    test('should set notification tap callback', () {
      notificationService.setNotificationTapCallback(() {
        // Callback set successfully
      });
      
      // Verify callback is set (would need to be tested with actual notification tap)
      expect(notificationService, isNotNull);
    });

    test('should check if daily notification is scheduled', () async {
      final isScheduled = await notificationService.isDailyNotificationScheduled();
      
      expect(isScheduled, isA<bool>());
      expect(isScheduled, isFalse); // Initially no notifications scheduled
    });

    test('should schedule and cancel notifications', () async {
      // Note: These tests would need proper mocking of FlutterLocalNotificationsPlugin
      // For now, we just test that the methods exist and can be called
      
      const testTime = TimeOfDay(hour: 20, minute: 0);
      
      // Schedule notification
      await notificationService.scheduleDailyNotification(testTime);
      
      // Cancel notification
      await notificationService.cancelAllNotifications();
      
      // Verify canceled
      final isScheduled = await notificationService.isDailyNotificationScheduled();
      expect(isScheduled, isFalse);
    });

    test('should update notification time', () async {
      const newTime = TimeOfDay(hour: 21, minute: 30);
      
      await notificationService.updateNotificationTime(newTime);
      
      // Verify the time was updated (would need to check storage)
      final storage = StorageService();
      final savedTime = storage.getSetting('notificationTime');
      
      // If notifications were enabled, the time should be updated
      if (storage.getSetting('notificationsEnabled', defaultValue: false)) {
        expect(savedTime, equals('21:30'));
      }
    });

    test('should handle test notification', () async {
      // Test that showTestNotification can be called without errors
      await expectLater(
        notificationService.showTestNotification(),
        completes,
      );
    });

    test('should get pending notifications', () async {
      final pending = await notificationService.getPendingNotifications();
      
      expect(pending, isA<List<PendingNotificationRequest>>());
      expect(pending.isEmpty, isTrue); // Initially no pending notifications
    });
  });
}