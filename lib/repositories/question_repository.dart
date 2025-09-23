import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/question.dart';
import '../models/answer_option.dart';
import '../services/database_helper.dart';

class QuestionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insertQuestion(Question question, String courseId) async {
    final db = await _databaseHelper.database;

    final correctAnswerIndex = question.options.indexWhere((o) => o.isCorrect);

    final values = {
      'id': question.id,
      'course_id': courseId,
      'category': question.category,
      'number': question.number,
      'text': question.question,
      'options': jsonEncode(question.options.map((o) => o.toMap()).toList()),
      'correct_answer': correctAnswerIndex,
      'assets': question.assets.isNotEmpty ? jsonEncode(question.assets) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await db.insert(
      DatabaseHelper.tableQuestions,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertQuestions(
    List<Question> questions,
    String courseId,
  ) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final question in questions) {
      final correctAnswerIndex = question.options.indexWhere(
        (o) => o.isCorrect,
      );

      final values = {
        'id': question.id,
        'course_id': courseId,
        'category': question.category,
        'number': question.number,
        'text': question.question,
        'options': jsonEncode(question.options.map((o) => o.toMap()).toList()),
        'correct_answer': correctAnswerIndex,
        'assets': question.assets.isNotEmpty
            ? jsonEncode(question.assets)
            : null,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      batch.insert(
        DatabaseHelper.tableQuestions,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Question>> getAllQuestions() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableQuestions,
      orderBy: 'number ASC',
    );

    return _mapToQuestions(maps);
  }

  Future<List<Question>> getQuestionsByCategory(String category) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableQuestions,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'number ASC',
    );

    return _mapToQuestions(maps);
  }

  Future<List<Question>> getQuestionsByCourse(String courseId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableQuestions,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'number ASC',
    );

    return _mapToQuestions(maps);
  }

  Future<List<Question>> getBookmarkedQuestions() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT q.* FROM ${DatabaseHelper.tableQuestions} q
      INNER JOIN ${DatabaseHelper.tableBookmarks} b ON q.id = b.question_id
      ORDER BY b.bookmarked_at DESC
    ''');

    return _mapToQuestions(maps);
  }

  Future<List<Question>> getIncorrectQuestions() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT q.* FROM ${DatabaseHelper.tableQuestions} q
      INNER JOIN ${DatabaseHelper.tableProgress} p ON q.id = p.question_id
      WHERE p.last_answer_correct = 0
      ORDER BY p.last_answered_at DESC
    ''');

    return _mapToQuestions(maps);
  }

  Future<void> addBookmark(String questionId) async {
    final db = await _databaseHelper.database;
    await db.insert(DatabaseHelper.tableBookmarks, {
      'question_id': questionId,
      'bookmarked_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeBookmark(String questionId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseHelper.tableBookmarks,
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<Set<String>> getBookmarkedQuestionIds() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBookmarks,
      columns: ['question_id'],
    );

    return maps.map((m) => m['question_id'] as String).toSet();
  }

  Future<void> updateProgress({
    required String questionId,
    required bool isCorrect,
  }) async {
    final db = await _databaseHelper.database;

    final existing = await db.query(
      DatabaseHelper.tableProgress,
      where: 'question_id = ?',
      whereArgs: [questionId],
    );

    if (existing.isEmpty) {
      await db.insert(DatabaseHelper.tableProgress, {
        'question_id': questionId,
        'times_shown': 1,
        'times_correct': isCorrect ? 1 : 0,
        'times_incorrect': isCorrect ? 0 : 1,
        'last_answered_at': DateTime.now().millisecondsSinceEpoch,
        'last_answer_correct': isCorrect ? 1 : 0,
      });
    } else {
      await db.rawUpdate(
        '''
        UPDATE ${DatabaseHelper.tableProgress}
        SET times_shown = times_shown + 1,
            times_correct = times_correct + ?,
            times_incorrect = times_incorrect + ?,
            last_answered_at = ?,
            last_answer_correct = ?
        WHERE question_id = ?
      ''',
        [
          isCorrect ? 1 : 0,
          isCorrect ? 0 : 1,
          DateTime.now().millisecondsSinceEpoch,
          isCorrect ? 1 : 0,
          questionId,
        ],
      );
    }
  }

  Future<Map<String, dynamic>> getProgress() async {
    final db = await _databaseHelper.database;

    final totalResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN last_answer_correct = 1 THEN 1 ELSE 0 END) as correct,
        SUM(CASE WHEN last_answer_correct = 0 THEN 1 ELSE 0 END) as incorrect
      FROM ${DatabaseHelper.tableProgress}
    ''');

    final categoriesResult = await db.rawQuery('''
      SELECT 
        q.category,
        COUNT(DISTINCT q.id) as total,
        COUNT(DISTINCT p.question_id) as answered,
        SUM(CASE WHEN p.last_answer_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM ${DatabaseHelper.tableQuestions} q
      LEFT JOIN ${DatabaseHelper.tableProgress} p ON q.id = p.question_id
      GROUP BY q.category
    ''');

    return {'overall': totalResult.first, 'byCategory': categoriesResult};
  }

  Future<int> getQuestionCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableQuestions}',
    );
    final count = result.first.values.first as int?;
    return count ?? 0;
  }

  Future<int> getBookmarkCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableBookmarks}',
    );
    final count = result.first.values.first as int?;
    return count ?? 0;
  }

  Future<int> getIncorrectCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM ${DatabaseHelper.tableProgress}
      WHERE last_answer_correct = 0
    ''');
    final count = result.first.values.first as int?;
    return count ?? 0;
  }

  List<Question> _mapToQuestions(List<Map<String, dynamic>> maps) {
    return maps.map((map) {
      final optionsJson = jsonDecode(map['options'] as String) as List;
      final options = optionsJson
          .map((o) => AnswerOption.fromMap(o as Map<String, dynamic>))
          .toList();

      final assets = map['assets'] != null
          ? (jsonDecode(map['assets'] as String) as List).cast<String>()
          : <String>[];

      return Question(
        id: map['id'] as String,
        number: map['number'] as int,
        question: map['text'] as String,
        options: options,
        category: map['category'] as String,
        assets: assets,
      );
    }).toList();
  }
}
