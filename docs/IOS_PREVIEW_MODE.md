# iOS Preview Mode

## Overview

The app now supports running with iOS-style UI directly on macOS, without requiring the iOS simulator. This is useful for quickly previewing and testing the iOS interface during development.

## Usage

### Run iOS UI on macOS

```bash
flutter run -d macos -t lib/main_ios_preview.dart
```

This launches the app on macOS but with:
- ✅ Cupertino widgets and design
- ✅ iOS-style navigation bars
- ✅ iOS page transitions with swipe-back gestures
- ✅ Cupertino dialogs and action sheets
- ✅ iOS switches and form controls
- ✅ 44pt tap targets (Apple HIG)
- ✅ Haptic feedback

### Normal macOS Run (Material Design)

```bash
flutter run -d macos
# or
flutter run -d macos -t lib/main.dart
```

This uses the default Material Design UI.

### iOS Simulator (Actual iOS)

```bash
flutter run -d ios
```

This runs the real iOS build in the simulator.

## Technical Details

### Architecture

The iOS preview mode works through a centralized platform detection system:

**PlatformHelper** (`lib/utils/platform_helper.dart`):
- Provides `useIOSStyle` getter that returns true for:
  - Actual iOS devices/simulator
  - macOS when iOS preview mode is enabled
- `enableIOSPreview()` method called in `main_ios_preview.dart`

**Adaptive Widgets** (`lib/widgets/platform/`):
All UI components check `PlatformHelper.useIOSStyle` instead of `Platform.isIOS`:

```dart
if (PlatformHelper.useIOSStyle) {
  return CupertinoButton(...);
} else {
  return ElevatedButton(...);
}
```

### Files Structure

- **lib/main.dart** - Default entrypoint (platform-adaptive)
- **lib/main_ios_preview.dart** - iOS preview entrypoint (forces iOS UI on macOS)
- **lib/utils/platform_helper.dart** - Platform detection logic
- **lib/widgets/platform/** - Adaptive widget library

## Benefits

1. **Faster iteration** - No need to launch iOS simulator
2. **Better debugging** - Use macOS debugging tools
3. **Side-by-side comparison** - Run both UIs simultaneously
4. **Resource efficient** - Lower memory usage than simulator

## Notes

- The iOS preview mode is only for UI testing
- Platform-specific APIs still behave as macOS
- For final iOS testing, always use actual iOS simulator/device
