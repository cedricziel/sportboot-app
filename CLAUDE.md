# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter application for learning German recreational boating license questions (SBF). Supports three courses:
- **SBF-See**: Sportbootführerschein See (284 questions)
- **SBF-Binnen**: Sportbootführerschein Binnen (253 questions)  
- **SBF-Binnen Segeln**: Binnen with sailing (300 questions)

Platforms: iOS and macOS native apps

## Commands

### Development
```bash
# Run the app
flutter run                # Default device
flutter run -d macos       # macOS
flutter run -d ios         # iOS simulator

# Testing
flutter test                          # All tests
flutter test test/unit/example_test.dart  # Single test file
flutter test --reporter compact      # CI format

# Code quality
flutter analyze                    # Static analysis
dart format .                      # Format code
dart format --set-exit-if-changed lib test tool  # Check formatting (CI)

# Dependencies
flutter pub get                    # Install dependencies
cd ios && pod install && cd ..    # iOS dependencies
cd macos && pod install && cd ..  # macOS dependencies
```

### Build & Release
```bash
# Build automation (uses Makefile)
make build           # Scrape and build question data
make bump           # Increment build number (auto-done by build-ios)
make build-ios      # Build iOS for release (includes bump)
make build-testflight  # Full TestFlight build with icons & splash
make icons          # Generate app icons
make splash         # Generate splash screens

# Manual builds
flutter build ios --release
flutter build macos --release
```

## Architecture

### Data Layer
- **SQLite Database** (`DatabaseHelper`): Primary storage for questions and progress
  - Tables: questions, progress, bookmarks, settings
  - Test isolation: Uses `DatabaseHelper.forTest(testName)` for deterministic test databases
- **Repository Pattern** (`QuestionRepository`): Database operations with caching via `CacheService`
- **SharedPreferences** (`StorageService`): Legacy storage, being migrated to SQLite
- **Migration Service**: Handles data migration from SharedPreferences to SQLite

### State Management
- **Provider Pattern**: Single `QuestionsProvider` manages all app state
  - Course selection and manifest management
  - Question loading and shuffling (cached per question ID)
  - Study session tracking
  - Progress and bookmark synchronization

### Data Flow
1. **Manifest Loading**: `assets/data/manifest.yaml` defines course structure and catalog relationships
2. **Question Data**: YAML files in `assets/data/courses/{course-id}/` contain questions by catalog
3. **Database Storage**: Questions loaded into SQLite on first use, cached for performance
4. **Provider Coordination**: `QuestionsProvider.init()` handles initialization, migration, and state updates
5. **UI Updates**: Screens consume provider state via `context.watch/read<QuestionsProvider>()`

### Key Services
- **DataLoader**: Parses YAML question files and course manifests
- **DatabaseHelper**: Singleton SQLite management with test isolation support
- **MigrationService**: Orchestrates data migration with progress callbacks
- **CacheService**: In-memory caching layer for database queries

### Testing Strategy
- **Test Database Isolation**: Each test gets its own SQLite database via `DatabaseHelper.forTest(testName)`
- **Fixture Data**: Test data in `test/fixtures/` for consistent testing
- **Repository Testing**: Uses dependency injection for mock database/cache
- **Provider Testing**: Injects test repositories for controlled state testing

## Course Structure

Courses are composed of catalogs (question banks):
- **Basisfragen**: Shared basic questions (72 questions)
- **Spezifische See**: Sea-specific (212 questions)
- **Spezifische Binnen**: Inland waterways (181 questions)
- **Spezifische Segeln**: Sailing-specific (47 questions)

Each course combines relevant catalogs with continuous question numbering.