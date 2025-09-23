import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sportboot_app/models/question.dart';
import 'package:sportboot_app/models/answer_option.dart';
import 'package:sportboot_app/repositories/question_repository.dart';

class TestDatabaseHelper {
  static int _dbCounter = 0;
  static final Map<String, Database> _databases = {};

  static Future<void> initializeTestDatabase() async {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  static Future<Database> getTestDatabase() async {
    // Create a unique database for each test to avoid locking issues
    final dbName = 'test_db_${++_dbCounter}.db';

    if (_databases.containsKey(dbName) && _databases[dbName]!.isOpen) {
      return _databases[dbName]!;
    }

    _databases[dbName] = await openDatabase(
      dbName,
      version: 2, // Match production database version
      onConfigure: (db) async {
        // Enable foreign keys to match production
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions (
            id TEXT PRIMARY KEY,
            course_id TEXT NOT NULL,
            category TEXT NOT NULL,
            number INTEGER NOT NULL,
            text TEXT NOT NULL,
            options TEXT NOT NULL,
            correct_answer INTEGER NOT NULL,
            assets TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_questions_category ON questions(category)
        ''');

        await db.execute('''
          CREATE INDEX idx_questions_course ON questions(course_id)
        ''');

        // Add composite index to match production
        await db.execute('''
          CREATE INDEX idx_questions_course_category ON questions(course_id, category)
        ''');

        await db.execute('''
          CREATE TABLE progress (
            question_id TEXT PRIMARY KEY,
            times_shown INTEGER DEFAULT 0,
            times_correct INTEGER DEFAULT 0,
            times_incorrect INTEGER DEFAULT 0,
            last_answered_at INTEGER,
            last_answer_correct INTEGER,
            FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
          )
        ''');

        // Add indexes for progress table
        await db.execute('''
          CREATE INDEX idx_progress_incorrect ON progress(times_incorrect) 
          WHERE times_incorrect > 0
        ''');

        await db.execute('''
          CREATE INDEX idx_progress_last_answered ON progress(last_answered_at DESC)
        ''');

        await db.execute('''
          CREATE TABLE bookmarks (
            question_id TEXT PRIMARY KEY,
            bookmarked_at INTEGER NOT NULL,
            FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
          )
        ''');

        // Add index for bookmarks
        await db.execute('''
          CREATE INDEX idx_bookmarks_date ON bookmarks(bookmarked_at DESC)
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );

    return _databases[dbName]!;
  }

  static Future<void> closeTestDatabase() async {
    // Close all test databases
    for (final db in _databases.values) {
      if (db.isOpen) {
        await db.close();
      }
    }
    _databases.clear();
  }

  static Future<void> clearTestDatabase() async {
    final db = await getTestDatabase();
    await db.delete('questions');
    await db.delete('progress');
    await db.delete('bookmarks');
    await db.delete('settings');
  }

  static List<Question> generateTestQuestions({
    int count = 10,
    String courseId = 'test-course',
    String category = 'Test Category',
    String? idPrefix,
  }) {
    return List.generate(count, (index) {
      final prefix = idPrefix ?? 'test';
      final questionId =
          'q_${prefix}_${category.replaceAll(' ', '_').toLowerCase()}_$index';
      return Question(
        id: questionId,
        number: index + 1,
        question: 'Test Question ${index + 1}?',
        options: [
          AnswerOption(
            id: 'a_${questionId}_0',
            text: 'Correct Answer',
            isCorrect: true,
          ),
          AnswerOption(
            id: 'a_${questionId}_1',
            text: 'Wrong Answer 1',
            isCorrect: false,
          ),
          AnswerOption(
            id: 'a_${questionId}_2',
            text: 'Wrong Answer 2',
            isCorrect: false,
          ),
          AnswerOption(
            id: 'a_${questionId}_3',
            text: 'Wrong Answer 3',
            isCorrect: false,
          ),
        ],
        category: category,
        assets: [],
      );
    });
  }

  /// Generate test questions with multiple categories
  static List<Question> generateMixedCategoryQuestions({
    required Map<String, int> categoryQuestionCounts,
    String courseId = 'test-course',
  }) {
    final questions = <Question>[];

    categoryQuestionCounts.forEach((category, count) {
      questions.addAll(
        generateTestQuestions(
          count: count,
          courseId: courseId,
          category: category,
          idPrefix: courseId,
        ),
      );
    });

    return questions;
  }

  /// Populate database with comprehensive test data for all courses
  static Future<void> populateTestDatabase(
    QuestionRepository repository,
  ) async {
    // Define test courses that match the actual manifest
    final courses = ['sbf-see', 'sbf-binnen', 'sbf-binnen-segeln'];

    // Define categories that match actual data
    final categories = [
      'Basisfragen',
      'Spezifische Fragen See',
      'Spezifische Fragen Binnen',
    ];

    for (final course in courses) {
      final allQuestions = <Question>[];

      // Add questions for each category
      for (int catIndex = 0; catIndex < categories.length; catIndex++) {
        final category = categories[catIndex];
        // Add 10 questions per category to ensure we have enough for random selection
        final questions = generateTestQuestions(
          count: 10,
          courseId: course,
          category: category,
          idPrefix: '${course}_cat$catIndex',
        );
        allQuestions.addAll(questions);
      }

      // Insert all questions for this course
      await repository.insertQuestions(allQuestions, course);
    }
  }

  /// Generate questions for quick quiz testing (ensures at least 14 questions)
  static Future<void> populateForQuickQuiz(
    QuestionRepository repository,
    String courseId,
  ) async {
    final questions = generateTestQuestions(
      count: 20, // More than 14 to allow random selection
      courseId: courseId,
      category: 'Basisfragen',
      idPrefix: 'quick_$courseId',
    );
    await repository.insertQuestions(questions, courseId);
  }
}
