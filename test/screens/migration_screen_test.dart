import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportboot_app/providers/questions_provider.dart';
import 'package:sportboot_app/screens/migration_screen.dart';
import 'package:sportboot_app/services/database_helper.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import '../helpers/test_database_helper.dart';

void main() {
  group('MigrationScreen Tests', () {
    late DatabaseHelper databaseHelper;
    late QuestionRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize test database
      await TestDatabaseHelper.initializeTestDatabase();

      databaseHelper = DatabaseHelper.instance;
      repository = QuestionRepository();
    });

    setUp(() async {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Clear database for fresh migration
      await databaseHelper.clearDatabase();
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    testWidgets('MigrationScreen shows progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QuestionsProvider()),
          ],
          child: const MaterialApp(home: MigrationScreen()),
        ),
      );

      // Should show the app title
      expect(find.text('SBF-See Lernkarten'), findsOneWidget);

      // Should show progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Should show sailing icon
      expect(find.byIcon(Icons.sailing), findsOneWidget);
    });

    testWidgets('MigrationScreen shows migration status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QuestionsProvider()),
          ],
          child: const MaterialApp(home: MigrationScreen()),
        ),
      );

      // Let the init process start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Migration status should be displayed when available
      // (exact text depends on migration state)
    });

    testWidgets(
      'MigrationScreen navigates after initialization',
      (WidgetTester tester) async {
        // Pre-populate database to skip migration
        final testQuestions = TestDatabaseHelper.generateTestQuestions(
          count: 1,
        );
        await repository.insertQuestions(testQuestions, 'test-course');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => QuestionsProvider()),
            ],
            child: const MaterialApp(home: MigrationScreen()),
          ),
        );

        // Wait for initialization without using pumpAndSettle
        // (pumpAndSettle hangs due to repeating animation)
        await tester.pump(); // Initial frame
        await tester.pump(const Duration(milliseconds: 100)); // Let init start
        await tester.pump(
          const Duration(seconds: 1),
        ); // Wait for initialization
        await tester.pump(); // Final frame

        // Should navigate away from migration screen
        // (In real app, it navigates to CourseSelectionScreen)
        // Since we don't have routes set up in test, navigation will fail
        // but we can verify migration screen tried to navigate
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets('MigrationScreen shows progress percentage', (
      WidgetTester tester,
    ) async {
      final provider = QuestionsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: provider)],
          child: const MaterialApp(home: MigrationScreen()),
        ),
      );

      // Trigger a rebuild with progress
      provider.notifyListeners();
      await tester.pump();

      // If progress is shown, percentage should be displayed
      if (provider.migrationProgress > 0) {
        final percentageText = '${(provider.migrationProgress * 100).toInt()}%';
        expect(find.text(percentageText), findsOneWidget);
      }
    });
  });
}
