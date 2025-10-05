import 'dart:io';

/// Helper class to determine platform behavior
class PlatformHelper {
  static bool _iosPreviewMode = false;

  /// Enable iOS preview mode (for macOS to display iOS UI)
  static void enableIOSPreview() {
    if (Platform.isMacOS) {
      _iosPreviewMode = true;
    }
  }

  /// Disable iOS preview mode (useful for testing)
  static void disableIOSPreview() {
    _iosPreviewMode = false;
  }

  /// Whether to use iOS-style widgets
  /// Returns true if running on iOS OR if iOS preview mode is enabled on macOS
  static bool get useIOSStyle {
    return Platform.isIOS || _iosPreviewMode;
  }

  /// Whether the actual platform is iOS (not preview mode)
  static bool get isActuallyIOS => Platform.isIOS;

  /// Whether the actual platform is macOS
  static bool get isActuallyMacOS => Platform.isMacOS;

  /// Whether we're in iOS preview mode
  static bool get isIOSPreview => _iosPreviewMode;
}
