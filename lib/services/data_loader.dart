import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/course.dart';
import '../models/question.dart';

class DataLoader {
  static const String _basePath = 'assets/data/courses/sbf-see/';
  
  static final Map<String, Course> _courseCache = {};

  static Future<Course> loadCourse(String filename) async {
    // Check cache first
    if (_courseCache.containsKey(filename)) {
      return _courseCache[filename]!;
    }

    try {
      final String yamlString = await rootBundle.loadString('$_basePath$filename');
      final dynamic yamlData = loadYaml(yamlString);
      
      // Convert YamlMap to regular Map
      final Map<String, dynamic> jsonData = _convertYamlToJson(yamlData);
      
      final Course course = Course.fromMap(jsonData);
      _courseCache[filename] = course;
      
      return course;
    } catch (e) {
      throw Exception('Failed to load course from $filename: $e');
    }
  }

  static Future<Course> loadAllQuestions() async {
    return loadCourse('all_questions.yaml');
  }

  static Future<Course> loadBasisfragen() async {
    return loadCourse('basisfragen.yaml');
  }

  static Future<Course> loadSpezifischeSee() async {
    return loadCourse('spezifische-see.yaml');
  }

  static Future<List<Course>> loadAllCourses() async {
    final futures = [
      loadBasisfragen(),
      loadSpezifischeSee(),
    ];
    
    return Future.wait(futures);
  }

  // Helper method to convert YAML types to JSON-compatible types
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

  // Clear cache if needed (e.g., for testing or refresh)
  static void clearCache() {
    _courseCache.clear();
  }
}