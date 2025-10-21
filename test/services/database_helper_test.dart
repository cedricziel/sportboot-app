import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sportboot_app/services/database_helper.dart';

void main() {
  group('DatabaseHelper Tests', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() async {
      // Initialize FFI for desktop testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create test-specific database instance
      final uniqueName =
          'db_helper_test_${DateTime.now().millisecondsSinceEpoch}';
      databaseHelper = DatabaseHelper.forTest(uniqueName);
      // Clear any existing test database
      await databaseHelper.clearDatabase();
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    tearDownAll(() async {
      await DatabaseHelper.cleanupTestInstances();
    });

    test('Database should be initialized with correct version', () async {
      final db = await databaseHelper.database;
      final version = await db.getVersion();
      expect(
        version,
        4,
      ); // Updated to match current database version (v4 adds daily_goals constraints)
    });

    test('Database should have all required tables', () async {
      final db = await databaseHelper.database;

      // Check if tables exist by querying sqlite_master
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(
        tableNames,
        containsAll([
          'questions',
          'progress',
          'bookmarks',
          'settings',
          'daily_goals',
        ]),
      );
    });

    test('Database should have correct indices', () async {
      final db = await databaseHelper.database;

      // Check if indices exist
      final indices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
      );

      final indexNames = indices.map((i) => i['name'] as String).toSet();

      expect(
        indexNames,
        containsAll([
          'idx_questions_category',
          'idx_questions_course',
          'idx_daily_goals_date',
        ]),
      );
    });

    test(
      'isDatabasePopulated should return false for empty database',
      () async {
        await databaseHelper.clearDatabase();
        final isPopulated = await databaseHelper.isDatabasePopulated();
        expect(isPopulated, false);
      },
    );

    test(
      'isDatabasePopulated should return true after adding questions',
      () async {
        final db = await databaseHelper.database;

        // Insert a test question
        await db.insert('questions', {
          'id': 'test_q_1',
          'course_id': 'test_course',
          'category': 'test',
          'number': 1,
          'text': 'Test question?',
          'options': '[]',
          'correct_answer': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        final isPopulated = await databaseHelper.isDatabasePopulated();
        expect(isPopulated, true);
      },
    );

    test('clearDatabase should remove all data', () async {
      final db = await databaseHelper.database;

      // Insert test data
      await db.insert('questions', {
        'id': 'test_q_1',
        'course_id': 'test_course',
        'category': 'test',
        'number': 1,
        'text': 'Test question?',
        'options': '[]',
        'correct_answer': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await db.insert('bookmarks', {
        'question_id': 'test_q_1',
        'bookmarked_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Clear database
      await databaseHelper.clearDatabase();

      // Check all tables are empty
      final questionsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM questions',
      );
      final questionsCount = questionsResult.first['count'] as int;

      final bookmarksResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookmarks',
      );
      final bookmarksCount = bookmarksResult.first['count'] as int;

      expect(questionsCount, 0);
      expect(bookmarksCount, 0);
    });

    test('Database should handle concurrent access', () async {
      // Test that multiple calls to database getter return the same instance
      final db1 = databaseHelper.database;
      final db2 = databaseHelper.database;
      final db3 = databaseHelper.database;

      final results = await Future.wait([db1, db2, db3]);

      // All should be the same instance
      expect(results[0], same(results[1]));
      expect(results[1], same(results[2]));
    });

    test('close should properly close database connection', () async {
      final db = await databaseHelper.database;
      expect(db.isOpen, true);

      await databaseHelper.close();
      expect(db.isOpen, false);
    });

    group('Daily Goals Constraints', () {
      test('Should allow valid daily goal', () async {
        final db = await databaseHelper.database;

        await db.insert('daily_goals', {
          'date': '2025-10-21',
          'target_questions': 10,
          'completed_questions': 5,
        });

        final result = await db.query('daily_goals');
        expect(result.length, 1);
        expect(result[0]['completed_questions'], 5);
      });

      test(
        'Should use default 0 for completed_questions when not provided',
        () async {
          final db = await databaseHelper.database;

          await db.insert('daily_goals', {
            'date': '2025-10-21',
            'target_questions': 10,
          });

          final result = await db.query('daily_goals');
          expect(result[0]['completed_questions'], 0);
        },
      );

      test('Should reject negative target_questions', () async {
        final db = await databaseHelper.database;

        expect(
          () async => await db.insert('daily_goals', {
            'date': '2025-10-21',
            'target_questions': -5,
            'completed_questions': 0,
          }),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('Should reject negative completed_questions', () async {
        final db = await databaseHelper.database;

        expect(
          () async => await db.insert('daily_goals', {
            'date': '2025-10-21',
            'target_questions': 10,
            'completed_questions': -1,
          }),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('Should reject completed_questions > target_questions', () async {
        final db = await databaseHelper.database;

        expect(
          () async => await db.insert('daily_goals', {
            'date': '2025-10-21',
            'target_questions': 10,
            'completed_questions': 15,
          }),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('Should allow completed_questions == target_questions', () async {
        final db = await databaseHelper.database;

        await db.insert('daily_goals', {
          'date': '2025-10-21',
          'target_questions': 10,
          'completed_questions': 10,
        });

        final result = await db.query('daily_goals');
        expect(result[0]['completed_questions'], 10);
      });
    });
  });
}
