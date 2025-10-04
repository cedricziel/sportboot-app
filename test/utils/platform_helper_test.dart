import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('PlatformHelper Tests', () {
    setUp(() {
      // Reset the iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });

    test('useIOSStyle returns false by default on non-iOS platforms', () {
      // On macOS (test environment), without iOS preview mode
      // This will be false unless we're actually on iOS
      final result = PlatformHelper.useIOSStyle;

      // On test environment (macOS), this should be false
      expect(result, isFalse);
    });

    test('enableIOSPreview enables iOS style on macOS', () {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      // Now useIOSStyle should return true
      expect(PlatformHelper.useIOSStyle, isTrue);
      expect(PlatformHelper.isIOSPreview, isTrue);
    });

    test('isActuallyMacOS returns true on macOS test environment', () {
      // In test environment, we're running on macOS
      expect(PlatformHelper.isActuallyMacOS, isTrue);
    });

    test('isActuallyIOS returns false on macOS test environment', () {
      // In test environment, we're not on actual iOS
      expect(PlatformHelper.isActuallyIOS, isFalse);
    });

    test('iOS preview mode persists across checks', () {
      // Enable iOS preview
      PlatformHelper.enableIOSPreview();

      // Check multiple times
      expect(PlatformHelper.useIOSStyle, isTrue);
      expect(PlatformHelper.useIOSStyle, isTrue);
      expect(PlatformHelper.isIOSPreview, isTrue);
    });
  });
}
