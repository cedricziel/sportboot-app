# Sportboot App

Flutter application for learning German recreational boating license questions (SBF - Sportbootführerschein).

## Supported Platforms

- **iOS** - iPhone and iPad
- **macOS** - Native desktop application

## Features

- Multiple course support (SBF-See, SBF-Binnen, SBF-Binnen-Segeln)
- Flashcard and quiz learning modes
- Progress tracking and statistics
- Bookmarking system
- Daily study reminders (iOS/macOS)
- Offline functionality

## Getting Started

### Prerequisites

- Flutter SDK (^3.8.1)
- Xcode (for iOS/macOS development)
- CocoaPods (for iOS/macOS dependencies)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/cedricziel/sportboot-app.git
cd sportboot-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Install iOS/macOS dependencies:
```bash
cd ios && pod install && cd ..
cd macos && pod install && cd ..
```

### Running the App

**iOS Simulator:**
```bash
flutter run -d ios
```

**macOS:**
```bash
flutter run -d macos
```

### Building for Release

**iOS:**
```bash
flutter build ios
```

**macOS:**
```bash
flutter build macos
```

## Project Structure

- `lib/` - Dart source code
  - `models/` - Data models
  - `providers/` - State management
  - `screens/` - UI screens
  - `services/` - Business logic and utilities
  - `widgets/` - Reusable UI components
- `assets/` - Static assets
  - `data/` - Question data in YAML format
  - `images/` - Question-related images
- `test/` - Unit and widget tests

## Testing

Run all tests:
```bash
flutter test
```

## License

This project is licensed under the MIT License.