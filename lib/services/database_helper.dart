import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'sportboot.db';
  static const int _databaseVersion = 1;

  static const String tableQuestions = 'questions';
  static const String tableProgress = 'progress';
  static const String tableBookmarks = 'bookmarks';
  static const String tableSettings = 'settings';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

    await db.execute('''
      CREATE TABLE $tableProgress (
        question_id TEXT PRIMARY KEY,
        times_shown INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        times_incorrect INTEGER DEFAULT 0,
        last_answered_at INTEGER,
        last_answer_correct INTEGER,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBookmarks (
        question_id TEXT PRIMARY KEY,
        bookmarked_at INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id)
      )
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
      await db.execute('DROP TABLE IF EXISTS $tableQuestions');
      await db.execute('DROP TABLE IF EXISTS $tableProgress');
      await db.execute('DROP TABLE IF EXISTS $tableBookmarks');
      await db.execute('DROP TABLE IF EXISTS $tableSettings');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableQuestions);
    await db.delete(tableProgress);
    await db.delete(tableBookmarks);
    await db.delete(tableSettings);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<bool> isDatabasePopulated() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableQuestions'),
    );
    return count != null && count > 0;
  }
}