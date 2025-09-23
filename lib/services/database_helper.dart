import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../exceptions/database_exceptions.dart';

class DatabaseHelper {
  static const String _databaseName = 'sportboot.db';
  static const int _databaseVersion =
      2; // Incremented for new indexes and foreign key constraints

  static const String tableQuestions = 'questions';
  static const String tableProgress = 'progress';
  static const String tableBookmarks = 'bookmarks';
  static const String tableSettings = 'settings';

  // Instance management
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static final Map<String, DatabaseHelper> _testInstances = {};

  // Instance-specific fields
  final String? _customDatabaseName;
  final bool _isTestDatabase;
  Database? _database;

  DatabaseHelper._privateConstructor({
    String? databaseName,
    bool isTestDatabase = false,
  }) : _customDatabaseName = databaseName,
       _isTestDatabase = isTestDatabase;

  // Factory for test databases with unique names
  factory DatabaseHelper.forTest(String testName) {
    // Check if we already have an instance for this test name
    // This allows sharing the same database within a test
    if (_testInstances.containsKey(testName)) {
      return _testInstances[testName]!;
    }

    // Create a new instance for this test name
    // Use timestamp to ensure uniqueness across test runs
    final dbName =
        'test_${testName}_${DateTime.now().microsecondsSinceEpoch}.db';
    _testInstances[testName] = DatabaseHelper._privateConstructor(
      databaseName: dbName,
      isTestDatabase: true,
    );
    return _testInstances[testName]!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final String dbName = _customDatabaseName ?? _databaseName;

      // For test databases, use in-memory database
      // This works with sqflite_common_ffi without platform channels
      final String path;
      if (_isTestDatabase) {
        // Use in-memory database for tests
        // This works with sqflite_common_ffi and avoids file system issues
        path = ':memory:';
      } else {
        // Production path using platform-specific database directory
        path = join(await getDatabasesPath(), dbName);
      }

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        // For in-memory databases, we need to ensure single instance
        singleInstance: _isTestDatabase ? false : true,
      );
    } catch (e, stackTrace) {
      throw DatabaseInitializationException(
        message: 'Failed to initialize database',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints for data integrity
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableQuestions (
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
      CREATE INDEX idx_questions_category ON $tableQuestions(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_questions_course ON $tableQuestions(course_id)
    ''');

    // Composite index for common query patterns
    await db.execute('''
      CREATE INDEX idx_questions_course_category ON $tableQuestions(course_id, category)
    ''');

    await db.execute('''
      CREATE TABLE $tableProgress (
        question_id TEXT PRIMARY KEY,
        times_shown INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        times_incorrect INTEGER DEFAULT 0,
        last_answered_at INTEGER,
        last_answer_correct INTEGER,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id) ON DELETE CASCADE
      )
    ''');

    // Index for finding questions with incorrect answers
    await db.execute('''
      CREATE INDEX idx_progress_incorrect ON $tableProgress(times_incorrect) 
      WHERE times_incorrect > 0
    ''');

    // Index for last answered questions
    await db.execute('''
      CREATE INDEX idx_progress_last_answered ON $tableProgress(last_answered_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE $tableBookmarks (
        question_id TEXT PRIMARY KEY,
        bookmarked_at INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id) ON DELETE CASCADE
      )
    ''');

    // Index for sorting bookmarks by date
    await db.execute('''
      CREATE INDEX idx_bookmarks_date ON $tableBookmarks(bookmarked_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Temporarily disable foreign keys to avoid constraint errors
      await db.execute('PRAGMA foreign_keys = OFF');

      // Drop tables in reverse dependency order (child tables first)
      await db.execute('DROP TABLE IF EXISTS $tableBookmarks');
      await db.execute('DROP TABLE IF EXISTS $tableProgress');
      await db.execute('DROP TABLE IF EXISTS $tableSettings');
      await db.execute('DROP TABLE IF EXISTS $tableQuestions');

      // Recreate all tables with new schema
      await _onCreate(db, newVersion);

      // Re-enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Execute a function within a database transaction
  Future<T> executeInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        return await action(txn);
      });
    } catch (e, stackTrace) {
      throw TransactionException(
        message: 'Transaction failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Execute multiple operations atomically in a batch
  Future<List<Object?>> executeBatch(
    void Function(Batch batch) operations,
  ) async {
    final db = await database;
    try {
      final batch = db.batch();
      operations(batch);
      return await batch.commit(noResult: false);
    } catch (e, stackTrace) {
      throw TransactionException(
        message: 'Batch operation failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Execute multiple operations atomically without returning results
  Future<void> executeBatchNoResult(
    void Function(Batch batch) operations,
  ) async {
    final db = await database;
    try {
      final batch = db.batch();
      operations(batch);
      await batch.commit(noResult: true);
    } catch (e, stackTrace) {
      throw TransactionException(
        message: 'Batch operation failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearDatabase() async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete(tableQuestions);
        await txn.delete(tableProgress);
        await txn.delete(tableBookmarks);
        await txn.delete(tableSettings);
      });
    } catch (e, stackTrace) {
      throw QueryException(
        message: 'Failed to clear database',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<bool> isDatabasePopulated() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableQuestions');
      final count = result.first.values.first as int?;
      return count != null && count > 0;
    } catch (e) {
      debugPrint('Error checking if database is populated: $e');
      return false;
    }
  }

  // Clean up a specific test instance
  static Future<void> cleanupTestInstance(String testName) async {
    if (_testInstances.containsKey(testName)) {
      final instance = _testInstances[testName]!;
      try {
        if (instance._database != null) {
          await instance.close();
        }
      } catch (e) {
        debugPrint('Error closing test database: $e');
      }
      _testInstances.remove(testName);
    }
  }

  // Clean up all test instances
  static Future<void> cleanupTestInstances() async {
    for (final instance in _testInstances.values) {
      try {
        if (instance._database != null) {
          await instance.close();
        }
      } catch (e) {
        debugPrint('Error closing test database: $e');
      }
    }
    _testInstances.clear();
  }
}
