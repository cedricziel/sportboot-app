import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('PlatformHelper Tests', () {
    setUp(() {
      // Reset the iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });

    test('useIOSStyle returns false by default on non-iOS platforms', () {
      // Without iOS preview mode, this should be false on non-iOS platforms
      final result = PlatformHelper.useIOSStyle;

      // Should be false on non-iOS platforms
      expect(result, Platform.isIOS);
    });

    test('enableIOSPreview enables iOS style on macOS', () {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      // useIOSStyle should return true only on macOS or iOS
      if (Platform.isMacOS) {
        expect(PlatformHelper.useIOSStyle, isTrue);
        expect(PlatformHelper.isIOSPreview, isTrue);
      } else {
        // On other platforms (like Linux in CI), preview mode doesn't enable
        expect(PlatformHelper.isIOSPreview, isFalse);
      }
    });

    test('isActuallyMacOS matches platform', () {
      // Should match the actual platform
      expect(PlatformHelper.isActuallyMacOS, Platform.isMacOS);
    });

    test('isActuallyIOS matches platform', () {
      // Should match the actual platform
      expect(PlatformHelper.isActuallyIOS, Platform.isIOS);
    });

    test('iOS preview mode persists across checks', () {
      // Enable iOS preview
      PlatformHelper.enableIOSPreview();

      // On macOS, preview mode should persist
      if (Platform.isMacOS) {
        expect(PlatformHelper.useIOSStyle, isTrue);
        expect(PlatformHelper.useIOSStyle, isTrue);
        expect(PlatformHelper.isIOSPreview, isTrue);
      } else {
        // On other platforms, preview mode is not supported
        expect(PlatformHelper.isIOSPreview, isFalse);
      }
    });
  });
}
