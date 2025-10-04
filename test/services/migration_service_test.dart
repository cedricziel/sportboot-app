import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/services/migration_service.dart';
import 'package:sportboot_app/services/database_helper.dart';
import 'package:sportboot_app/services/cache_service.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import '../helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MigrationService Tests', () {
    late MigrationService migrationService;
    late DatabaseHelper databaseHelper;
    late QuestionRepository repository;

    setUpAll(() async {
      // Initialize FFI for desktop testing
      await TestDatabaseHelper.initializeTestDatabase();
    });

    setUp(() async {
      // Create test-specific instances with shared database
      final uniqueName =
          'migration_test_${DateTime.now().millisecondsSinceEpoch}';
      databaseHelper = TestDatabaseHelper.createTestDatabaseHelper(uniqueName);

      // Create repository with the same database helper
      repository = QuestionRepository(
        databaseHelper: databaseHelper,
        cache: CacheService(),
      );

      // Create migration service with the same database helper and repository
      migrationService = MigrationService(
        questionRepository: repository,
        databaseHelper: databaseHelper,
      );

      await databaseHelper.clearDatabase();
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    tearDownAll(() async {
      await DatabaseHelper.cleanupTestInstances();
    });

    test(
      'migrateDataIfNeeded should skip migration when database is populated',
      () async {
        // Pre-populate database with test data
        final testQuestions = TestDatabaseHelper.generateTestQuestions(
          count: 1,
        );
        await repository.insertQuestions(testQuestions, 'test-course');

        bool progressCalled = false;
        String lastStatus = '';

        await migrationService.migrateDataIfNeeded(
          onProgress: (progress) {
            progressCalled = true;
          },
          onStatusUpdate: (status) {
            lastStatus = status;
          },
        );

        expect(lastStatus, 'Database already populated');
        expect(progressCalled, true);
      },
    );

    test(
      'migrateDataIfNeeded should perform migration when database is empty',
      () async {
        double lastProgress = 0;
        String lastStatus = '';
        List<String> statusUpdates = [];

        await migrationService.migrateDataIfNeeded(
          onProgress: (progress) {
            lastProgress = progress;
          },
          onStatusUpdate: (status) {
            lastStatus = status;
            statusUpdates.add(status);
          },
        );

        // Check progress reached 100%
        expect(lastProgress, 1.0);

        // Check status updates included expected stages
        expect(statusUpdates.any((s) => s.contains('Starting')), true);
        expect(statusUpdates.any((s) => s.contains('Loading')), true);
        expect(lastStatus, contains('completed'));

        // Verify data was actually migrated
        final questionCount = await repository.getQuestionCount();
        expect(questionCount, greaterThan(0));
      },
    );

    test('forceMigration should clear and re-migrate data', () async {
      // Pre-populate database
      final testQuestions = TestDatabaseHelper.generateTestQuestions(count: 5);
      await repository.insertQuestions(testQuestions, 'test-course');

      // Verify data exists
      var questionCount = await repository.getQuestionCount();
      expect(questionCount, 5);

      double lastProgress = 0;
      String lastStatus = '';

      await migrationService.forceMigration(
        onProgress: (progress) {
          lastProgress = progress;
        },
        onStatusUpdate: (status) {
          lastStatus = status;
        },
      );

      // Check migration completed
      expect(lastProgress, 1.0);
      expect(lastStatus, contains('completed'));

      // Verify data was re-migrated (should have real questions now)
      questionCount = await repository.getQuestionCount();
      expect(questionCount, greaterThan(0));
    });

    test('migration progress callbacks should be called in order', () async {
      List<double> progressValues = [];
      List<String> statusMessages = [];

      await migrationService.migrateDataIfNeeded(
        onProgress: (progress) {
          progressValues.add(progress);
        },
        onStatusUpdate: (status) {
          statusMessages.add(status);
        },
      );

      // Progress should be monotonically increasing
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }

      // Should end at 100%
      if (progressValues.isNotEmpty) {
        expect(progressValues.last, 1.0);
      }

      // Status messages should follow expected pattern
      expect(
        statusMessages.first,
        anyOf(contains('Starting'), contains('already populated')),
      );
    });

    test('migration should handle errors gracefully', () async {
      // This test would ideally mock a failure scenario
      // For now, we'll just ensure the migration completes without throwing

      bool errorThrown = false;

      try {
        await migrationService.migrateDataIfNeeded(
          onProgress: (_) {},
          onStatusUpdate: (_) {},
        );
      } catch (e) {
        errorThrown = true;
      }

      // Migration should handle errors internally and not throw
      // (In a real scenario, you might want different behavior)
      expect(errorThrown, false);
    });

    test('background YAML parsing should work correctly', () async {
      // Test that the static method for background parsing works
      // This is implicitly tested by the migration tests above

      // The parseYamlInBackground method is private, so we test it indirectly
      // through the migration process
      await migrationService.migrateDataIfNeeded(
        onProgress: (_) {},
        onStatusUpdate: (_) {},
      );

      // If we got here without errors, background parsing worked
      expect(true, true);
    });
  });
}
