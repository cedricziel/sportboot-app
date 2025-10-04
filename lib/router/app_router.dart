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
        builder: (context, state) => const MigrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.courseSelection,
        name: 'courseSelection',
        builder: (context, state) => const CourseSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: AppRoutes.flashcard,
        name: 'flashcard',
        builder: (context, state) => const FlashcardScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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
