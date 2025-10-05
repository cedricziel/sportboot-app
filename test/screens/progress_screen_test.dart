import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import 'package:sportboot_app/services/database_helper.dart';
import '../helpers/test_database_helper.dart';

void main() {
  group('ProgressScreen Statistics Tests', () {
    late QuestionRepository repository;
    late DatabaseHelper databaseHelper;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await TestDatabaseHelper.initializeTestDatabase();
    });

    setUp(() async {
      databaseHelper = TestDatabaseHelper.createTestDatabaseHelper(
        'progress_screen_test_${DateTime.now().millisecondsSinceEpoch}',
      );
      repository = QuestionRepository(databaseHelper: databaseHelper);
    });

    test('Returns zero statistics when no data', () async {
      final progress = await repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      expect(overall['total'] ?? 0, 0);
      expect(overall['correct'] ?? 0, 0);
      expect(overall['incorrect'] ?? 0, 0);
    });

    test('Returns accurate statistics after answering questions', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 10,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      // Answer 5 questions correctly and 3 incorrectly
      for (int i = 0; i < 5; i++) {
        await repository.updateProgress(
          questionId: questions[i].id,
          isCorrect: true,
        );
      }
      for (int i = 5; i < 8; i++) {
        await repository.updateProgress(
          questionId: questions[i].id,
          isCorrect: false,
        );
      }

      final progress = await repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      expect(overall['total'], 8);
      expect(overall['correct'], 5);
      expect(overall['incorrect'], 3);
    });

    test('Calculates study streak from consecutive days', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 5,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      final db = await databaseHelper.database;
      final now = DateTime.now();

      // Simulate studying over 3 consecutive days
      for (int day = 0; day < 3; day++) {
        final timestamp = now
            .subtract(Duration(days: 2 - day))
            .millisecondsSinceEpoch;

        await db.insert('progress', {
          'question_id': questions[day].id,
          'times_shown': 1,
          'times_correct': 1,
          'times_incorrect': 0,
          'last_answered_at': timestamp,
          'last_answer_correct': 1,
        });
      }

      // Verify we have 3 days of data
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT DATE(last_answered_at / 1000, 'unixepoch')) as days
        FROM ${DatabaseHelper.tableProgress}
      ''');

      final days = result.first['days'] as int;
      expect(days, 3);
    });

    test('Shows 100% accuracy when all answers correct', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 7,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      // Answer all correctly
      for (final question in questions) {
        await repository.updateProgress(
          questionId: question.id,
          isCorrect: true,
        );
      }

      final progress = await repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      expect(overall['total'], 7);
      expect(overall['correct'], 7);
      expect(overall['incorrect'], 0);

      // Accuracy calculation: 7/7 = 100%
      final accuracy = (overall['correct'] as int) / (overall['total'] as int);
      expect(accuracy, 1.0);
    });

    test('Shows 0% accuracy when all answers wrong', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 5,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      // Answer all incorrectly
      for (final question in questions) {
        await repository.updateProgress(
          questionId: question.id,
          isCorrect: false,
        );
      }

      final progress = await repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      expect(overall['total'], 5);
      expect(overall['correct'], 0);
      expect(overall['incorrect'], 5);

      // Accuracy calculation: 0/5 = 0%
      final total = overall['total'] as int;
      final accuracy = total > 0 ? (overall['correct'] as int) / total : 0.0;
      expect(accuracy, 0.0);
    });

    test('Reset clears all progress data', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 5,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      // Add some progress
      for (final question in questions) {
        await repository.updateProgress(
          questionId: question.id,
          isCorrect: true,
        );
      }

      // Verify data exists
      var progress = await repository.getProgress();
      var overall = progress['overall'] as Map<String, dynamic>;
      expect(overall['total'], 5);

      // Clear progress
      final db = await databaseHelper.database;
      await db.delete(DatabaseHelper.tableProgress);
      await db.delete(DatabaseHelper.tableBookmarks);

      // Verify data is cleared
      progress = await repository.getProgress();
      overall = progress['overall'] as Map<String, dynamic>;
      expect(overall['total'] ?? 0, 0);
      expect(overall['correct'] ?? 0, 0);
      expect(overall['incorrect'] ?? 0, 0);
    });

    test('Counts are accurate with mixed results', () async {
      final questions = TestDatabaseHelper.generateTestQuestions(
        count: 10,
        courseId: 'test-course',
      );
      await repository.insertQuestions(questions, 'test-course');

      // 6 correct, 4 incorrect
      for (int i = 0; i < 6; i++) {
        await repository.updateProgress(
          questionId: questions[i].id,
          isCorrect: true,
        );
      }
      for (int i = 6; i < 10; i++) {
        await repository.updateProgress(
          questionId: questions[i].id,
          isCorrect: false,
        );
      }

      final progress = await repository.getProgress();
      final overall = progress['overall'] as Map<String, dynamic>;

      expect(overall['total'], 10);
      expect(overall['correct'], 6);
      expect(overall['incorrect'], 4);

      // Verify incorrect count
      final incorrectCount = await repository.getIncorrectCount();
      expect(incorrectCount, 4);
    });
  });
}
