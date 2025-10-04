import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:screenshot/screenshot.dart';
import 'package:sportboot_app/main_ios_preview.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotController = ScreenshotController();

  group('Screenshot Tests', () {
    testWidgets('Generate screenshots for all screens', (tester) async {
      // Helper function to build app with specific brightness
      Widget buildAppWithBrightness(Brightness brightness) {
        return MediaQuery(
          data: MediaQueryData(platformBrightness: brightness),
          child: Screenshot(
            controller: screenshotController,
            child: const app.MyApp(),
          ),
        );
      }

      // Helper function to take screenshot
      Future<void> takeScreenshot(String name) async {
        if (kIsWeb) return;
        await tester.pumpAndSettle();

        final imageBytes = await screenshotController.capture(pixelRatio: 2.0);

        if (imageBytes != null) {
          // Save to current directory (sandboxed container on macOS)
          // The script will copy these to the project directory
          final currentDir = Directory.current.path;
          final screenshotsDir = path.join(currentDir, 'screenshots');

          // Save screenshot to file
          final directory = Directory(screenshotsDir);
          if (!directory.existsSync()) {
            directory.createSync(recursive: true);
          }
          final filePath = path.join(screenshotsDir, '$name.png');
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);
          debugPrint('Screenshot saved: $filePath');
        }
      }

      // Helper function to capture all screens
      Future<void> captureAllScreens(String suffix) async {
        // Wait for migration to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot 1: Course Selection Screen
        await takeScreenshot('01_course_selection$suffix');
        await tester.pumpAndSettle();

        // Select a course (SBF-See)
        final courseCard = find.text('SBF-See');
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Screenshot 2: Home Screen
        await takeScreenshot('02_home_screen$suffix');
        await tester.pumpAndSettle();

        // Navigate to Progress screen - use Cupertino icons for iOS preview
        final progressIcon = find.byIcon(CupertinoIcons.chart_bar);
        if (progressIcon.evaluate().isNotEmpty) {
          await tester.tap(progressIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Screenshot 3: Progress Screen
          await takeScreenshot('03_progress_screen$suffix');
          await tester.pumpAndSettle();

          // Go back to home using router
          final context = tester.element(
            find.byType(CupertinoPageScaffold).first,
          );
          context.pop();
          await tester.pumpAndSettle();
        }

        // Navigate to Settings screen - use Cupertino icons for iOS preview
        final settingsIcon = find.byIcon(CupertinoIcons.settings);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Screenshot 4: Settings Screen
          await takeScreenshot('04_settings_screen$suffix');
          await tester.pumpAndSettle();

          // Go back to home using router
          final context = tester.element(
            find.byType(CupertinoPageScaffold).first,
          );
          context.pop();
          await tester.pumpAndSettle();
        }

        // Start a quiz
        final quickQuizCard = find.text('Schnell-Quiz');
        if (quickQuizCard.evaluate().isNotEmpty) {
          await tester.tap(quickQuizCard);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Screenshot 5: Quiz Screen
          await takeScreenshot('05_quiz_screen$suffix');
          await tester.pumpAndSettle();

          // Go back to home using router
          final context = tester.element(
            find.byType(CupertinoPageScaffold).first,
          );
          context.pop();
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        // Navigate to flashcard mode by tapping a category
        final basisfragenCard = find.text('Basisfragen');
        if (basisfragenCard.evaluate().isNotEmpty) {
          await tester.tap(basisfragenCard);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Select flashcard mode from the action sheet
          final flashcardButton = find.text('Karteikarten');
          if (flashcardButton.evaluate().isNotEmpty) {
            await tester.tap(flashcardButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Screenshot 6: Flashcard Screen
            await takeScreenshot('06_flashcard_screen$suffix');
            await tester.pumpAndSettle();
          }
        }
      }

      // Generate light mode screenshots first
      debugPrint('📸 Generating light mode screenshots...');
      await tester.pumpWidget(buildAppWithBrightness(Brightness.light));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await captureAllScreens('');

      // Generate dark mode screenshots
      debugPrint('📸 Generating dark mode screenshots...');
      await tester.pumpWidget(buildAppWithBrightness(Brightness.dark));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await captureAllScreens('_dark');

      debugPrint('✅ Screenshots generated successfully!');
      debugPrint('   Light mode screens:');
      debugPrint('   - 01_course_selection.png');
      debugPrint('   - 02_home_screen.png');
      debugPrint('   - 03_progress_screen.png');
      debugPrint('   - 04_settings_screen.png');
      debugPrint('   - 05_quiz_screen.png');
      debugPrint('   - 06_flashcard_screen.png (if available)');
      debugPrint('   Dark mode screens:');
      debugPrint('   - 01_course_selection_dark.png');
      debugPrint('   - 02_home_screen_dark.png');
      debugPrint('   - 03_progress_screen_dark.png');
      debugPrint('   - 04_settings_screen_dark.png');
      debugPrint('   - 05_quiz_screen_dark.png');
      debugPrint('   - 06_flashcard_screen_dark.png (if available)');
    });
  });
}
