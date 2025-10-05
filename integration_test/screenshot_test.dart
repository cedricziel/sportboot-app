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
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final themeName = brightness == Brightness.light ? '' : '_dark';
      final testName = 'Generate ${brightness.name} mode screenshots';

      testWidgets(testName, (tester) async {
        // Helper function to build app with specific brightness
        Widget buildAppWithBrightness() {
          return MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: Screenshot(
              controller: screenshotController,
              child: const app.MyApp(),
            ),
          );
        }

        // Helper function to take screenshot
        Future<void> takeScreenshot(String screenName) async {
          if (kIsWeb) return;
          await tester.pumpAndSettle();

          final imageBytes = await screenshotController.capture(
            pixelRatio: 2.0,
          );

          if (imageBytes != null) {
            final currentDir = Directory.current.path;
            final screenshotsDir = path.join(currentDir, 'screenshots');

            final directory = Directory(screenshotsDir);
            if (!directory.existsSync()) {
              directory.createSync(recursive: true);
            }

            final fileName = '$screenName$themeName.png';
            final filePath = path.join(screenshotsDir, fileName);
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            debugPrint('Screenshot saved: $filePath');
          }
        }

        // Start the app
        debugPrint('📸 Generating ${brightness.name} mode screenshots...');
        await tester.pumpWidget(buildAppWithBrightness());
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot 1: Course Selection Screen
        await takeScreenshot('01_course_selection');
        await tester.pumpAndSettle();

        // Select a course (SBF-See)
        final courseCard = find.text('SBF-See');
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Screenshot 2: Home Screen
        await takeScreenshot('02_home_screen');
        await tester.pumpAndSettle();

        // Navigate to Progress screen
        final progressIcon = find.byIcon(CupertinoIcons.chart_bar);
        if (progressIcon.evaluate().isNotEmpty) {
          await tester.tap(progressIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Screenshot 3: Progress Screen
          await takeScreenshot('03_progress_screen');
          await tester.pumpAndSettle();

          // Go back to home
          final context = tester.element(
            find.byType(CupertinoPageScaffold).first,
          );
          context.pop();
          await tester.pumpAndSettle();
        }

        // Navigate to Settings screen
        final settingsIcon = find.byIcon(CupertinoIcons.settings);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Screenshot 4: Settings Screen
          await takeScreenshot('04_settings_screen');
          await tester.pumpAndSettle();

          // Go back to home
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
          await takeScreenshot('05_quiz_screen');
          await tester.pumpAndSettle();
        }

        debugPrint('✅ ${brightness.name} mode screenshots completed!');
      });
    }
  });
}
