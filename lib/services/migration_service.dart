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
    final isPopulated = await _databaseHelper.isDatabasePopulated();
    
    if (isPopulated) {
      onStatusUpdate('Database already populated');
      onProgress(1.0);
      return;
    }

    onStatusUpdate('Starting data migration...');
    await _performMigration(onProgress: onProgress, onStatusUpdate: onStatusUpdate);
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
        onStatusUpdate('Loading $courseId...');
        
        final yamlString = await rootBundle.loadString('$_basePath$file');
        
        onStatusUpdate('Parsing $courseId...');
        final questions = await compute(_parseYamlInBackground, yamlString);
        
        onStatusUpdate('Saving $courseId to database...');
        await _questionRepository.insertQuestions(questions, courseId);
        
        processedFiles++;
        onProgress(processedFiles / totalFiles);
      }

      onStatusUpdate('Migration completed successfully');
      onProgress(1.0);
    } catch (e) {
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
    
    await _performMigration(onProgress: onProgress, onStatusUpdate: onStatusUpdate);
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