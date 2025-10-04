import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../screens/migration_screen.dart';
import '../screens/course_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/platform_helper.dart';

/// Route paths as constants for type-safe navigation
class AppRoutes {
  static const String migration = '/migration';
  static const String courseSelection = '/course-selection';
  static const String home = '/';
  static const String quiz = '/quiz';
  static const String flashcard = '/flashcard';
  static const String progress = '/progress';
  static const String settings = '/settings';
}

/// Creates and configures the app's router
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.migration,
    routes: [
      GoRoute(
        path: AppRoutes.migration,
        name: 'migration',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const MigrationScreen(),
          fullscreenDialog: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.courseSelection,
        name: 'courseSelection',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const CourseSelectionScreen(),
          fullscreenDialog: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const HomeScreen(),
          fullscreenDialog: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const QuizScreen(),
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.flashcard,
        name: 'flashcard',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const FlashcardScreen(),
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.progress,
        name: 'progress',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const ProgressScreen(),
          fullscreenDialog: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const SettingsScreen(),
          fullscreenDialog: true,
        ),
      ),
    ],
    redirect: (context, state) {
      // Get the provider without listening to changes
      final provider = Provider.of<QuestionsProvider>(context, listen: false);

      final currentLocation = state.uri.path;

      // Allow migration screen to always be accessible
      if (currentLocation == AppRoutes.migration) {
        return null;
      }

      // If no course is selected and not navigating to course selection,
      // redirect to course selection
      if (provider.selectedCourseManifest == null &&
          currentLocation != AppRoutes.courseSelection) {
        return AppRoutes.courseSelection;
      }

      return null; // No redirect needed
    },
  );
}

/// Builds a platform-adaptive page with proper transitions
Page _buildPage(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
}) {
  if (PlatformHelper.useIOSStyle) {
    return CupertinoPage(
      key: state.pageKey,
      child: child,
      fullscreenDialog: fullscreenDialog,
    );
  }

  return MaterialPage(
    key: state.pageKey,
    child: child,
    fullscreenDialog: fullscreenDialog,
  );
}
