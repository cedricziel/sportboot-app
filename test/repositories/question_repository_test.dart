import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import 'package:sportboot_app/models/question.dart';
import 'package:sportboot_app/models/answer_option.dart';
import 'package:sportboot_app/services/database_helper.dart';
import '../helpers/test_database_helper.dart';

void main() {
  group('QuestionRepository Tests', () {
    late QuestionRepository repository;
    late DatabaseHelper databaseHelper;
    late List<Question> testQuestions;
    final testName = 'question_repository_test';

    setUpAll(() async {
      // Initialize FFI for desktop testing
      await TestDatabaseHelper.initializeTestDatabase();
    });

    setUp(() async {
      // Create test-specific instances for each test
      final uniqueName = '${testName}_${DateTime.now().millisecondsSinceEpoch}';
      databaseHelper = TestDatabaseHelper.createTestDatabaseHelper(uniqueName);
      // Use the same database helper instance for the repository
      repository = QuestionRepository(databaseHelper: databaseHelper);
      await databaseHelper.clearDatabase();

      // Generate test questions
      testQuestions = TestDatabaseHelper.generateTestQuestions(count: 5);
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    tearDownAll(() async {
      // Clean up all test database instances
      await DatabaseHelper.cleanupTestInstances();
    });

    test('insertQuestion should add a single question to database', () async {
      final question = testQuestions.first;

      final id = await repository.insertQuestion(question, 'test-course');

      expect(id, greaterThan(0));

      // Verify question was inserted
      final db = await databaseHelper.database;
      final result = await db.query(
        'questions',
        where: 'id = ?',
        whereArgs: [question.id],
      );

      expect(result.length, 1);
      expect(result.first['text'], question.question);
      expect(result.first['course_id'], 'test-course');
    });

    test('insertQuestions should batch insert multiple questions', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      // Verify all questions were inserted
      final db = await databaseHelper.database;
      final result = await db.query('questions');

      expect(result.length, testQuestions.length);
    });

    test('getAllQuestions should return all questions', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      final questions = await repository.getAllQuestions();

      expect(questions.length, testQuestions.length);
      expect(questions.first.id, testQuestions.first.id);
    });

    test('getQuestionsByCategory should filter by category', () async {
      // Insert questions with different categories
      final category1Questions = TestDatabaseHelper.generateTestQuestions(
        count: 3,
        category: 'Category 1',
        idPrefix: 'cat1',
      );
      final category2Questions = TestDatabaseHelper.generateTestQuestions(
        count: 2,
        category: 'Category 2',
        idPrefix: 'cat2',
      );

      await repository.insertQuestions(category1Questions, 'test-course');
      await repository.insertQuestions(category2Questions, 'test-course');

      final result = await repository.getQuestionsByCategory('Category 1');

      expect(result.length, 3);
      expect(result.every((q) => q.category == 'Category 1'), true);
    });

    test('getQuestionsByCourse should filter by course', () async {
      // Insert questions for different courses
      await repository.insertQuestions(testQuestions.sublist(0, 3), 'course-1');
      await repository.insertQuestions(testQuestions.sublist(3), 'course-2');

      final result = await repository.getQuestionsByCourse('course-1');

      expect(result.length, 3);
    });

    test('getQuestionsByCatalogs should filter by multiple catalogs', () async {
      // Insert questions with different categories (catalogs)
      final basisfragen = TestDatabaseHelper.generateTestQuestions(
        count: 3,
        category: 'basisfragen',
        idPrefix: 'basis',
      );
      final spezifischeSee = TestDatabaseHelper.generateTestQuestions(
        count: 2,
        category: 'spezifische-see',
        idPrefix: 'see',
      );
      final spezifischeBinnen = TestDatabaseHelper.generateTestQuestions(
        count: 2,
        category: 'spezifische-binnen',
        idPrefix: 'binnen',
      );

      await repository.insertQuestions(basisfragen, 'sbf-see');
      await repository.insertQuestions(spezifischeSee, 'sbf-see');
      await repository.insertQuestions(spezifischeBinnen, 'sbf-binnen');

      // Query multiple catalogs at once
      final result = await repository.getQuestionsByCatalogs([
        'basisfragen',
        'spezifische-see',
      ]);

      expect(result.length, 5);
      expect(
        result.every(
          (q) => q.category == 'basisfragen' || q.category == 'spezifische-see',
        ),
        true,
      );
    });

    test(
      'getQuestionsByCatalogs should return empty list for empty input',
      () async {
        final result = await repository.getQuestionsByCatalogs([]);

        expect(result, isEmpty);
      },
    );

    test('getQuestionsByCatalogs should handle single catalog', () async {
      final basisfragen = TestDatabaseHelper.generateTestQuestions(
        count: 3,
        category: 'basisfragen',
        idPrefix: 'basis',
      );

      await repository.insertQuestions(basisfragen, 'sbf-see');

      final result = await repository.getQuestionsByCatalogs(['basisfragen']);

      expect(result.length, 3);
      expect(result.every((q) => q.category == 'basisfragen'), true);
    });

    test('addBookmark and removeBookmark should manage bookmarks', () async {
      await repository.insertQuestions(testQuestions, 'test-course');
      final questionId = testQuestions.first.id;

      // Add bookmark
      await repository.addBookmark(questionId);

      var bookmarks = await repository.getBookmarkedQuestionIds();
      expect(bookmarks.contains(questionId), true);

      // Remove bookmark
      await repository.removeBookmark(questionId);

      bookmarks = await repository.getBookmarkedQuestionIds();
      expect(bookmarks.contains(questionId), false);
    });

    test(
      'getBookmarkedQuestions should return only bookmarked questions',
      () async {
        await repository.insertQuestions(testQuestions, 'test-course');

        // Bookmark first two questions
        await repository.addBookmark(testQuestions[0].id);
        await repository.addBookmark(testQuestions[1].id);

        final bookmarked = await repository.getBookmarkedQuestions();

        expect(bookmarked.length, 2);
        expect(
          bookmarked.map((q) => q.id),
          containsAll([testQuestions[0].id, testQuestions[1].id]),
        );
      },
    );

    test('updateProgress should track question answers', () async {
      await repository.insertQuestions(testQuestions, 'test-course');
      final questionId = testQuestions.first.id;

      // Answer correctly
      await repository.updateProgress(questionId: questionId, isCorrect: true);

      // Check progress was recorded
      final db = await databaseHelper.database;
      final result = await db.query(
        'progress',
        where: 'question_id = ?',
        whereArgs: [questionId],
      );

      expect(result.length, 1);
      expect(result.first['times_correct'], 1);
      expect(result.first['times_incorrect'], 0);
      expect(result.first['last_answer_correct'], 1);

      // Answer incorrectly
      await repository.updateProgress(questionId: questionId, isCorrect: false);

      final updatedResult = await db.query(
        'progress',
        where: 'question_id = ?',
        whereArgs: [questionId],
      );

      expect(updatedResult.first['times_correct'], 1);
      expect(updatedResult.first['times_incorrect'], 1);
      expect(updatedResult.first['last_answer_correct'], 0);
    });

    test(
      'getIncorrectQuestions should return questions answered incorrectly',
      () async {
        await repository.insertQuestions(testQuestions, 'test-course');

        // Mark some questions as incorrect
        await repository.updateProgress(
          questionId: testQuestions[0].id,
          isCorrect: false,
        );
        await repository.updateProgress(
          questionId: testQuestions[1].id,
          isCorrect: false,
        );
        await repository.updateProgress(
          questionId: testQuestions[2].id,
          isCorrect: true,
        );

        final incorrect = await repository.getIncorrectQuestions();

        expect(incorrect.length, 2);
        expect(
          incorrect.map((q) => q.id),
          containsAll([testQuestions[0].id, testQuestions[1].id]),
        );
      },
    );

    test('getProgress should return overall statistics', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      // Create some progress
      await repository.updateProgress(
        questionId: testQuestions[0].id,
        isCorrect: true,
      );
      await repository.updateProgress(
        questionId: testQuestions[1].id,
        isCorrect: false,
      );
      await repository.updateProgress(
        questionId: testQuestions[2].id,
        isCorrect: true,
      );

      final progress = await repository.getProgress();

      expect(progress['overall'], isNotNull);
      final overall = progress['overall'] as Map<String, dynamic>;
      expect(overall['total'], 3);
      expect(overall['correct'], 2);
      expect(overall['incorrect'], 1);
    });

    test('getQuestionCount should return correct count', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      final count = await repository.getQuestionCount();

      expect(count, testQuestions.length);
    });

    test('getBookmarkCount should return correct count', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      await repository.addBookmark(testQuestions[0].id);
      await repository.addBookmark(testQuestions[1].id);

      final count = await repository.getBookmarkCount();

      expect(count, 2);
    });

    test('getIncorrectCount should return correct count', () async {
      await repository.insertQuestions(testQuestions, 'test-course');

      await repository.updateProgress(
        questionId: testQuestions[0].id,
        isCorrect: false,
      );
      await repository.updateProgress(
        questionId: testQuestions[1].id,
        isCorrect: false,
      );
      await repository.updateProgress(
        questionId: testQuestions[2].id,
        isCorrect: true,
      );

      final count = await repository.getIncorrectCount();

      expect(count, 2);
    });

    test('Question deserialization should preserve all fields', () async {
      const question = Question(
        id: 'test_id',
        number: 42,
        question: 'What is the answer?',
        options: [
          AnswerOption(id: 'a1', text: 'Option 1', isCorrect: true),
          AnswerOption(id: 'a2', text: 'Option 2', isCorrect: false),
        ],
        category: 'Test Category',
        assets: ['image1.png', 'image2.png'],
      );

      await repository.insertQuestion(question, 'test-course');

      final retrieved = await repository.getAllQuestions();

      expect(retrieved.length, 1);
      final result = retrieved.first;

      expect(result.id, question.id);
      expect(result.number, question.number);
      expect(result.question, question.question);
      expect(result.category, question.category);
      expect(result.assets, question.assets);
      expect(result.options.length, question.options.length);
      expect(result.options.first.id, question.options.first.id);
      expect(result.options.first.text, question.options.first.text);
      expect(result.options.first.isCorrect, question.options.first.isCorrect);
    });
  });
}
