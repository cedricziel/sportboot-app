import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../repositories/question_repository.dart';
import 'database_helper.dart';

class MigrationService {
  final QuestionRepository _questionRepository = QuestionRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static const String _basePath = 'assets/data/courses/';

  Future<void> migrateDataIfNeeded({
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    try {
      debugPrint('[MigrationService] Checking if database is populated...');
      final isPopulated = await _databaseHelper.isDatabasePopulated();
      debugPrint('[MigrationService] Database populated: $isPopulated');

      if (isPopulated) {
        final count = await _questionRepository.getQuestionCount();
        debugPrint('[MigrationService] Database already has $count questions');
        onStatusUpdate('Database already populated');
        onProgress(1.0);
        return;
      }

      debugPrint('[MigrationService] Starting data migration...');
      onStatusUpdate('Starting data migration...');
      await _performMigration(
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
    } catch (e, stackTrace) {
      debugPrint('[MigrationService] Error during migration check: $e');
      debugPrint('[MigrationService] Stack trace: $stackTrace');
      onStatusUpdate('Migration error: $e');
      rethrow;
    }
  }

  Future<void> _performMigration({
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    try {
      onProgress(0.0);

      final filesToLoad = [
        ('sbf-see/all_questions.yaml', 'all'),
        ('sbf-see/basisfragen.yaml', 'basisfragen'),
        ('sbf-see/spezifische-see.yaml', 'spezifische-see'),
      ];

      final totalFiles = filesToLoad.length;
      var processedFiles = 0;

      for (final (file, courseId) in filesToLoad) {
        debugPrint(
          '[MigrationService] Processing file: $file for course: $courseId',
        );
        onStatusUpdate('Loading $courseId...');

        try {
          final yamlString = await rootBundle.loadString('$_basePath$file');
          debugPrint(
            '[MigrationService] Loaded YAML file, size: ${yamlString.length} bytes',
          );

          onStatusUpdate('Parsing $courseId...');
          final questions = await compute(_parseYamlInBackground, yamlString);
          debugPrint(
            '[MigrationService] Parsed ${questions.length} questions from $courseId',
          );

          onStatusUpdate('Saving $courseId to database...');
          await _questionRepository.insertQuestions(questions, courseId);
          debugPrint(
            '[MigrationService] Saved ${questions.length} questions to database',
          );

          processedFiles++;
          onProgress(processedFiles / totalFiles);
        } catch (e) {
          debugPrint('[MigrationService] Error processing $file: $e');
          throw Exception('Failed to process $file: $e');
        }
      }

      final totalQuestions = await _questionRepository.getQuestionCount();
      debugPrint(
        '[MigrationService] Migration completed. Total questions in database: $totalQuestions',
      );
      onStatusUpdate('Migration completed successfully');
      onProgress(1.0);
    } catch (e) {
      debugPrint('[MigrationService] Migration failed: $e');
      onStatusUpdate('Migration failed: $e');
      rethrow;
    }
  }

  Future<void> forceMigration({
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    onStatusUpdate('Clearing existing data...');
    await _databaseHelper.clearDatabase();

    await _performMigration(
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  static List<Question> _parseYamlInBackground(String yamlString) {
    final yamlData = loadYaml(yamlString);
    final jsonData = _convertYamlToJson(yamlData);
    final course = Course.fromMap(jsonData);
    return course.questions;
  }

  static dynamic _convertYamlToJson(dynamic yamlData) {
    if (yamlData is YamlMap) {
      final Map<String, dynamic> map = {};
      yamlData.forEach((key, value) {
        map[key.toString()] = _convertYamlToJson(value);
      });
      return map;
    } else if (yamlData is YamlList) {
      return yamlData.map((item) => _convertYamlToJson(item)).toList();
    } else {
      return yamlData;
    }
  }
}
