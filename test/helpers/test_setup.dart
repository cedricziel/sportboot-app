import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Common test setup utilities to ensure consistent test environment
class TestSetup {
  static bool _initialized = false;

  /// Initialize test environment with database and shared preferences
  /// Call this in setUpAll() for tests that use database or storage
  static Future<void> initializeTestEnvironment({
    Map<String, Object>? sharedPrefsValues,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Only initialize FFI once per test run
    if (!_initialized) {
      // Initialize FFI for database testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }

    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues(sharedPrefsValues ?? {});
  }

  /// Reset shared preferences for a fresh test
  static void resetSharedPreferences({Map<String, Object>? values}) {
    SharedPreferences.setMockInitialValues(values ?? {});
  }
}
