import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sportboot_app/models/question.dart';
import 'package:sportboot_app/models/answer_option.dart';

class TestDatabaseHelper {
  static Database? _testDatabase;

  static Future<void> initializeTestDatabase() async {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  static Future<Database> getTestDatabase() async {
    if (_testDatabase != null && _testDatabase!.isOpen) {
      return _testDatabase!;
    }

    _testDatabase = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
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

        await db.execute('''
          CREATE TABLE progress (
            question_id TEXT PRIMARY KEY,
            times_shown INTEGER DEFAULT 0,
            times_correct INTEGER DEFAULT 0,
            times_incorrect INTEGER DEFAULT 0,
            last_answered_at INTEGER,
            last_answer_correct INTEGER,
            FOREIGN KEY (question_id) REFERENCES questions (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE bookmarks (
            question_id TEXT PRIMARY KEY,
            bookmarked_at INTEGER NOT NULL,
            FOREIGN KEY (question_id) REFERENCES questions (id)
          )
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

    return _testDatabase!;
  }

  static Future<void> closeTestDatabase() async {
    if (_testDatabase != null && _testDatabase!.isOpen) {
      await _testDatabase!.close();
    }
    _testDatabase = null;
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
  }) {
    return List.generate(count, (index) {
      final questionId = 'q_test_$index';
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
}