import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/question.dart';
import '../models/answer_option.dart';
import '../services/database_helper.dart';
import '../services/cache_service.dart';
import '../exceptions/database_exceptions.dart';

class QuestionRepository {
  final DatabaseHelper _databaseHelper;
  final CacheService _cache;

  // Constructor with dependency injection
  QuestionRepository({DatabaseHelper? databaseHelper, CacheService? cache})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
      _cache = cache ?? CacheService();

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
    if (questions.isEmpty) return;

    // Validate data before insertion
    for (final question in questions) {
      if (question.id.isEmpty) {
        throw DataValidationException(
          message: 'Question ID cannot be empty',
          field: 'id',
          invalidValue: question.id,
        );
      }
    }

    // Invalidate cache for this course
    _cache.invalidatePattern('questions_course_$courseId.*');
    _cache.invalidate('all_questions');

    await _databaseHelper.executeBatchNoResult((batch) {
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
          'options': jsonEncode(
            question.options.map((o) => o.toMap()).toList(),
          ),
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
    });
  }

  Future<List<Question>> getAllQuestions() async {
    return await _cache.getOrCompute<List<Question>>('all_questions', () async {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableQuestions,
        orderBy: 'number ASC',
      );
      return _mapToQuestions(maps);
    }, duration: const Duration(minutes: 10));
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

  /// Get questions with pagination support
  Future<PaginatedResult<Question>> getQuestionsPaginated({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? courseId,
  }) async {
    if (page < 1) {
      throw DataValidationException(
        message: 'Page number must be greater than 0',
        field: 'page',
        invalidValue: page,
      );
    }

    if (pageSize < 1 || pageSize > 100) {
      throw DataValidationException(
        message: 'Page size must be between 1 and 100',
        field: 'pageSize',
        invalidValue: pageSize,
      );
    }

    final db = await _databaseHelper.database;
    final offset = (page - 1) * pageSize;

    // Build where clause
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (courseId != null) {
      whereClauses.add('course_id = ?');
      whereArgs.add(courseId);
    }

    final whereClause = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableQuestions}${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );

    final totalCount = (countResult.first['count'] as int?) ?? 0;

    // Get paginated results
    final maps = await db.query(
      DatabaseHelper.tableQuestions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'number ASC',
      limit: pageSize,
      offset: offset,
    );

    final questions = _mapToQuestions(maps);

    return PaginatedResult(
      items: questions,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: (totalCount / pageSize).ceil(),
    );
  }

  /// Clear all caches
  void clearCache() {
    _cache.clear();
  }

  /// Dispose resources
  void dispose() {
    _cache.dispose();
  }
}

/// Result class for paginated queries
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
