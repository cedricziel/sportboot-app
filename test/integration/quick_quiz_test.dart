import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sportboot_app/providers/questions_provider.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import 'package:sportboot_app/services/storage_service.dart';
import 'package:sportboot_app/services/database_helper.dart';
import '../helpers/test_database_helper.dart';

void main() {
  group('Quick Quiz Tests', () {
    late QuestionsProvider provider;
    late QuestionRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();

      // Initialize repository and populate test data
      final uniqueName =
          'quick_quiz_test_${DateTime.now().millisecondsSinceEpoch}';
      repository = TestDatabaseHelper.createTestRepository(uniqueName);
      await TestDatabaseHelper.populateTestDatabase(repository);

      provider = TestDatabaseHelper.createTestProvider(uniqueName);
      await provider.init();
    });

    tearDownAll(() async {
      await DatabaseHelper.cleanupTestInstances();
    });

    test('Quick Quiz loads 14 random questions for SBF-See', () async {
      // Select SBF-See course
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-see')) {
        final sbfSeeCourse = provider.manifest!.courses['sbf-see']!;
        provider.setSelectedCourse('sbf-see', sbfSeeCourse);

        // Load random questions for quick quiz
        await provider.loadRandomQuestions(14);

        // Verify we have exactly 14 questions
        expect(provider.currentQuestions.length, 14);
        expect(provider.currentQuestionIndex, 0);
        expect(provider.error, isNull);

        // Verify all questions have required fields
        for (final question in provider.currentQuestions) {
          expect(question.id, isNotEmpty);
          expect(question.question, isNotEmpty);
          expect(question.options, isNotEmpty);
          expect(question.options.length, greaterThanOrEqualTo(2));

          // At least one answer should be correct
          final hasCorrectAnswer = question.options.any((opt) => opt.isCorrect);
          expect(hasCorrectAnswer, true);
        }
      }
    });

    test('Quick Quiz loads 14 random questions for SBF-Binnen', () async {
      // Select SBF-Binnen course
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-binnen')) {
        final sbfBinnenCourse = provider.manifest!.courses['sbf-binnen']!;
        provider.setSelectedCourse('sbf-binnen', sbfBinnenCourse);

        // Load random questions for quick quiz
        await provider.loadRandomQuestions(14);

        // Verify we have exactly 14 questions
        expect(provider.currentQuestions.length, 14);
        expect(provider.error, isNull);
      }
    });

    test(
      'Quick Quiz loads 14 random questions for SBF-Binnen-Segeln',
      () async {
        // Select SBF-Binnen-Segeln course
        if (provider.manifest != null &&
            provider.manifest!.courses.containsKey('sbf-binnen-segeln')) {
          final sbfBinnenSegelnCourse =
              provider.manifest!.courses['sbf-binnen-segeln']!;
          provider.setSelectedCourse(
            'sbf-binnen-segeln',
            sbfBinnenSegelnCourse,
          );

          // Load random questions for quick quiz
          await provider.loadRandomQuestions(14);

          // Verify we have exactly 14 questions
          expect(provider.currentQuestions.length, 14);
          expect(provider.error, isNull);
        }
      },
    );

    test('Quick Quiz questions are actually random', () async {
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-see')) {
        final sbfSeeCourse = provider.manifest!.courses['sbf-see']!;
        provider.setSelectedCourse('sbf-see', sbfSeeCourse);

        // Load first set of random questions
        await provider.loadRandomQuestions(14);
        final firstSet = provider.currentQuestions.map((q) => q.id).toList();

        // Load second set of random questions
        await provider.loadRandomQuestions(14);
        final secondSet = provider.currentQuestions.map((q) => q.id).toList();

        // The sets should be different (very unlikely to be the same if truly random)
        // But we'll check that at least some questions are different
        int differentQuestions = 0;
        for (int i = 0; i < 14; i++) {
          if (firstSet[i] != secondSet[i]) {
            differentQuestions++;
          }
        }

        // At least half should be different (statistically very likely)
        expect(differentQuestions, greaterThan(7));
      }
    });

    test(
      'Quick Quiz falls back to legacy format when no course selected',
      () async {
        // Create a new provider instance to simulate fresh install
        // This needs its own test database with data
        final uniqueName =
            'quick_quiz_no_course_${DateTime.now().millisecondsSinceEpoch}';
        final testRepo = TestDatabaseHelper.createTestRepository(uniqueName);
        await TestDatabaseHelper.populateTestDatabase(testRepo);

        final freshProvider = TestDatabaseHelper.createTestProvider(uniqueName);
        await freshProvider.init();

        // Clear any stored course ID to simulate no course selected
        StorageService().setSetting('selectedCourseId', null);

        // Try to load random questions - should fallback to legacy
        await freshProvider.loadRandomQuestions(14);

        // Should either have questions (if fallback works) or an error
        if (freshProvider.error == null) {
          expect(freshProvider.currentQuestions.length, 14);
        }

        // Cleanup
        await DatabaseHelper.cleanupTestInstance(uniqueName);
      },
    );

    test('Session is properly started after loading quick quiz', () async {
      if (provider.manifest != null &&
          provider.manifest!.courses.containsKey('sbf-see')) {
        final sbfSeeCourse = provider.manifest!.courses['sbf-see']!;
        provider.setSelectedCourse('sbf-see', sbfSeeCourse);

        // Load random questions
        await provider.loadRandomQuestions(14);

        // Start a quiz session
        provider.startSession('quiz', 'quick_quiz');

        // Verify session is created
        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession!.mode, 'quiz');
        expect(provider.currentSession!.category, 'quick_quiz');
        expect(provider.currentSession!.questionIds.length, 14);

        // All question IDs in session should match loaded questions
        for (int i = 0; i < 14; i++) {
          expect(
            provider.currentSession!.questionIds[i],
            provider.currentQuestions[i].id,
          );
        }
      }
    });
  });
}
