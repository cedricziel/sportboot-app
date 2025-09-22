import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:sportboot_app/models/course.dart';
import 'package:sportboot_app/models/course_manifest.dart';

dynamic convertYamlToMap(dynamic yamlData) {
  if (yamlData is YamlMap) {
    final map = <String, dynamic>{};
    yamlData.forEach((key, value) {
      map[key.toString()] = convertYamlToMap(value);
    });
    return map;
  } else if (yamlData is YamlList) {
    return yamlData.map((item) => convertYamlToMap(item)).toList();
  } else if (yamlData is Map) {
    final map = <String, dynamic>{};
    yamlData.forEach((key, value) {
      map[key.toString()] = convertYamlToMap(value);
    });
    return map;
  } else if (yamlData is List) {
    return yamlData.map((item) => convertYamlToMap(item)).toList();
  }
  return yamlData;
}

void main() async {
  print('🔍 Verifying question data...\n');
  
  // Check manifest
  print('📋 Checking manifest...');
  final manifestFile = File('assets/data/manifest.yaml');
  if (!manifestFile.existsSync()) {
    print('  ❌ Manifest file not found');
    exit(1);
  }
  
  final manifestContent = await manifestFile.readAsString();
  final manifestYaml = loadYaml(manifestContent);
  final manifestMap = convertYamlToMap(manifestYaml);
  final manifest = Manifest.fromMap(manifestMap);
  print('  ✅ Manifest loaded successfully');
  print('  📚 Found ${manifest.courses.length} courses:');
  
  for (final course in manifest.courses.values) {
    print('     - ${course.name} (${course.id})');
    print('       Categories: ${course.categories.map((c) => c.id).join(", ")}');
  }
  
  // Check each course file
  print('\n📖 Checking course files...');
  for (final courseManifest in manifest.courses.values) {
    final filePath = 'assets/data/courses/${courseManifest.id}/questions.yaml';
    final file = File(filePath);
    
    if (!file.existsSync()) {
      print('  ❌ File not found: $filePath');
      continue;
    }
    
    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      final courseMap = convertYamlToMap(yaml);
      final course = Course.fromMap(courseMap);
      
      print('\n  ✅ ${courseManifest.name}:');
      print('     File: $filePath');
      print('     Questions: ${course.questions.length}');
      print('     Version: ${course.version}');
      print('     Source: ${course.source}');
      
      // Verify all questions have IDs
      var hasIds = true;
      var hasAnswerIds = true;
      for (final question in course.questions) {
        if (!question.id.startsWith('q_')) {
          hasIds = false;
          print('     ❌ Question missing proper ID: ${question.id}');
        }
        for (final answer in question.options) {
          if (!answer.id.startsWith('a_')) {
            hasAnswerIds = false;
            print('     ❌ Answer missing proper ID: ${answer.id}');
          }
        }
      }
      
      if (hasIds) {
        print('     ✅ All questions have valid IDs');
      }
      if (hasAnswerIds) {
        print('     ✅ All answers have valid IDs');
      }
      
      // Check for unique IDs
      final questionIds = <String>{};
      final answerIds = <String>{};
      var duplicateQuestions = 0;
      var duplicateAnswers = 0;
      
      for (final question in course.questions) {
        if (questionIds.contains(question.id)) {
          duplicateQuestions++;
        }
        questionIds.add(question.id);
        
        for (final answer in question.options) {
          if (answerIds.contains(answer.id)) {
            duplicateAnswers++;
          }
          answerIds.add(answer.id);
        }
      }
      
      if (duplicateQuestions == 0) {
        print('     ✅ All question IDs are unique');
      } else {
        print('     ❌ Found $duplicateQuestions duplicate question IDs');
      }
      
      if (duplicateAnswers == 0) {
        print('     ✅ All answer IDs are unique');
      } else {
        print('     ❌ Found $duplicateAnswers duplicate answer IDs');
      }
      
    } catch (e) {
      print('  ❌ Error loading ${courseManifest.name}: $e');
    }
  }
  
  print('\n✅ Verification complete!');
}