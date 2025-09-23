import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportboot_app/providers/questions_provider.dart';
import 'package:sportboot_app/services/storage_service.dart';
import 'package:sportboot_app/services/database_helper.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import '../helpers/test_database_helper.dart';

void main() {
  group('Course Selection Persistence Tests', () {
    late StorageService storage;
    late DatabaseHelper databaseHelper;
    late QuestionRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Initialize test database
      await TestDatabaseHelper.initializeTestDatabase();
      
      storage = StorageService();
      await storage.init();
      
      databaseHelper = DatabaseHelper.instance;
      repository = QuestionRepository();
    });

    setUp(() async {
      // Reset mock values for each test
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      
      // Clear and setup test database with some questions
      await databaseHelper.clearDatabase();
      final testQuestions = TestDatabaseHelper.generateTestQuestions(
        count: 10,
        courseId: 'sbf-see',
        category: 'Test',
      );
      await repository.insertQuestions(testQuestions, 'sbf-see');
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    test('Course selection is persisted to storage', () async {
      final provider = QuestionsProvider();
      await provider.init();

      // Select a course
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-binnen')) {
        final course = provider.manifest!.courses['sbf-binnen']!;
        provider.setSelectedCourse('sbf-binnen', course);

        // Verify it's set in the provider
        expect(provider.selectedCourseId, 'sbf-binnen');
        expect(provider.selectedCourseManifest, isNotNull);
        expect(provider.selectedCourseManifest!.id, 'sbf-binnen');

        // Verify it's persisted to storage
        final storedId = storage.getSetting('selectedCourseId');
        expect(storedId, 'sbf-binnen');
      }
    });

    test('Course selection is restored on app restart', () async {
      // Simulate previous selection
      storage.setSetting('selectedCourseId', 'sbf-see');

      // Create new provider (simulating app restart)
      final provider = QuestionsProvider();
      await provider.init();

      // The selection should be restored
      expect(provider.selectedCourseId, 'sbf-see');
      expect(provider.selectedCourseManifest, isNotNull);
      expect(provider.selectedCourseManifest!.id, 'sbf-see');
    });

    test('Invalid stored course ID is handled gracefully', () async {
      // Set an invalid course ID
      storage.setSetting('selectedCourseId', 'non-existent-course');

      // Create new provider
      final provider = QuestionsProvider();
      await provider.init();

      // Should not crash, selectedCourseId will be the invalid one but manifest will be null
      expect(provider.selectedCourseId, 'non-existent-course');
      expect(provider.selectedCourseManifest, isNull);
    });

    test('Course switch updates both provider and storage', () async {
      final provider = QuestionsProvider();
      await provider.init();

      if (provider.manifest != null && provider.manifest!.courses.length >= 2) {
        // Select first course
        final firstCourse = provider.manifest!.courses.entries.first;
        provider.setSelectedCourse(firstCourse.key, firstCourse.value);
        expect(provider.selectedCourseId, firstCourse.key);
        expect(storage.getSetting('selectedCourseId'), firstCourse.key);

        // Switch to second course
        final secondCourse = provider.manifest!.courses.entries.elementAt(1);
        provider.setSelectedCourse(secondCourse.key, secondCourse.value);
        expect(provider.selectedCourseId, secondCourse.key);
        expect(storage.getSetting('selectedCourseId'), secondCourse.key);
      }
    });

    test('Course manifest has required fields for all courses', () async {
      final provider = QuestionsProvider();
      await provider.init();

      expect(provider.manifest, isNotNull);
      expect(provider.manifest!.courses, isNotEmpty);

      // Check each course has required fields
      provider.manifest!.courses.forEach((id, course) {
        expect(course.id, id);
        expect(course.name, isNotEmpty);
        expect(course.shortName, isNotEmpty);
        expect(course.icon, isNotEmpty);
        expect(course.categories, isNotEmpty);

        // Each category should have required fields
        for (final category in course.categories) {
          expect(category.id, isNotEmpty);
          expect(category.name, isNotEmpty);
          expect(category.description, isNotEmpty);
        }
      });
    });

    test('loadAllQuestions uses selected course', () async {
      final provider = QuestionsProvider();
      await provider.init();

      // Test with SBF-See
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-see')) {
        final sbfSee = provider.manifest!.courses['sbf-see']!;
        provider.setSelectedCourse('sbf-see', sbfSee);

        await provider.loadAllQuestions();
        final sbfSeeCount = provider.currentQuestions.length;
        expect(sbfSeeCount, greaterThan(0));

        // Switch to SBF-Binnen and verify different question count
        if (provider.manifest!.courses.containsKey('sbf-binnen')) {
          final sbfBinnen = provider.manifest!.courses['sbf-binnen']!;
          provider.setSelectedCourse('sbf-binnen', sbfBinnen);

          await provider.loadAllQuestions();
          final sbfBinnenCount = provider.currentQuestions.length;
          expect(sbfBinnenCount, greaterThan(0));

          // The courses should have different question counts
          expect(sbfSeeCount != sbfBinnenCount, true);
        }
      }
    });
  });
}
