# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application for learning German recreational boating license questions (SBF-See - Sportbootführerschein See). It's a flashcard and quiz app with 287 questions organized in categories.

## Commands

### Development
```bash
# Run the app in debug mode
flutter run

# Run on a specific device
flutter run -d macos  # Run on macOS
flutter run -d chrome # Run in Chrome (web)

# Hot reload (when app is running)
r  # in terminal while flutter run is active

# Hot restart (when app is running)
R  # in terminal while flutter run is active
```

### Build
```bash
# Build for specific platforms
flutter build macos    # Build macOS app
flutter build ios      # Build iOS app  
flutter build apk      # Build Android APK
flutter build web      # Build for web
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Format code
dart format .
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Show outdated packages
flutter pub outdated
```

## Architecture

### State Management
- Uses Provider package for state management
- Main provider: `QuestionsProvider` - manages questions, study sessions, and user progress
- Provider is initialized in `main.dart` and consumed throughout the app

### Data Flow
1. **Data Loading**: YAML files in `assets/data/courses/sbf-see/` contain question data
2. **Storage**: `StorageService` handles local persistence using SharedPreferences
3. **Provider**: `QuestionsProvider` coordinates between data loading and UI state
4. **Screens**: Consume provider state and handle user interactions

### Key Components

**Models** (`lib/models/`):
- `Question`: Core data model for questions with multiple choice answers
- `Course`: Groups questions into learning categories
- `StudySession`: Tracks user progress during learning sessions
- `AnswerOption`: Represents individual answer choices

**Services** (`lib/services/`):
- `DataLoader`: Loads and parses YAML question data from assets
- `StorageService`: Manages local storage for progress, bookmarks, and settings

**Screens** (`lib/screens/`):
- `HomeScreen`: Main navigation hub with category selection
- `FlashcardScreen`: Flip-card style learning mode
- `QuizScreen`: Multiple choice quiz with immediate feedback
- `ProgressScreen`: Statistics and learning progress visualization
- `SettingsScreen`: App configuration options

### Question Categories
- **All Questions** (287 total): Complete question set
- **Basisfragen** (73 questions): Basic knowledge questions
- **Spezifische See** (214 questions): Sea-specific questions
- **Bookmarks**: User-marked questions for review
- **Incorrect**: Questions answered incorrectly for focused practice

### Learning Modes
1. **Flashcard Mode**: Question on front, answer on back with flip animation
2. **Quiz Mode**: Multiple choice with immediate feedback and progress tracking

Both modes support:
- Progress tracking and statistics
- Bookmarking for later review
- Session-based learning with results summary