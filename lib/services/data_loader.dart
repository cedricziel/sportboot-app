import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/course.dart';
import '../models/course_manifest.dart';

class DataLoader {
  static const String _basePath = 'assets/data/courses/';
  static const String _manifestPath = 'assets/data/manifest.yaml';

  static final Map<String, Course> _courseCache = {};
  static Manifest? _manifestCache;

  // Load the manifest file
  static Future<Manifest> loadManifest() async {
    if (_manifestCache != null) {
      return _manifestCache!;
    }

    try {
      final String yamlString = await rootBundle.loadString(_manifestPath);
      final dynamic yamlData = loadYaml(yamlString);
      final Map<String, dynamic> jsonData = _convertYamlToJson(yamlData);

      _manifestCache = Manifest.fromMap(jsonData);
      return _manifestCache!;
    } catch (e) {
      throw Exception('Failed to load manifest: $e');
    }
  }

  // Load course by ID from the new structure
  static Future<Course> loadCourseById(String courseId) async {
    final cacheKey = 'course_$courseId';
    if (_courseCache.containsKey(cacheKey)) {
      return _courseCache[cacheKey]!;
    }

    try {
      // First, ensure manifest is loaded to get course info
      final manifest = await loadManifest();
      final courseManifest = manifest.courses[courseId];

      if (courseManifest == null) {
        throw Exception('Course $courseId not found in manifest');
      }

      // Load the course questions file
      final String yamlString = await rootBundle.loadString(
        '$_basePath$courseId/questions.yaml',
      );
      final dynamic yamlData = loadYaml(yamlString);
      final Map<String, dynamic> jsonData = _convertYamlToJson(yamlData);

      final Course course = Course.fromMap(jsonData);
      _courseCache[cacheKey] = course;

      return course;
    } catch (e) {
      throw Exception('Failed to load course $courseId: $e');
    }
  }

  // Legacy method for backward compatibility
  static Future<Course> loadCourse(String filename) async {
    // Check cache first
    if (_courseCache.containsKey(filename)) {
      return _courseCache[filename]!;
    }

    try {
      // Try to load from sbf-see directory for backward compatibility
      final String yamlString = await rootBundle.loadString(
        '${_basePath}sbf-see/$filename',
      );
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
    final futures = [loadBasisfragen(), loadSpezifischeSee()];

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
    _manifestCache = null;
  }
}
