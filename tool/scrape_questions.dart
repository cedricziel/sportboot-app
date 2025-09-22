#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:yaml/yaml.dart';

class Catalog {
  final String id;
  final String name;
  final String description;
  final String url;
  final String? alternateUrl;
  final int questionCount;

  Catalog({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    this.alternateUrl,
    required this.questionCount,
  });

  factory Catalog.fromYaml(String id, Map yaml) {
    return Catalog(
      id: id,
      name: yaml['name'],
      description: yaml['description'],
      url: yaml['url'],
      alternateUrl: yaml['alternateUrl'],
      questionCount: yaml['questionCount'],
    );
  }
}

class Course {
  final String id;
  final String name;
  final List<String> catalogIds;

  Course({required this.id, required this.name, required this.catalogIds});

  factory Course.fromYaml(String id, Map yaml) {
    final catalogs = (yaml['catalogs'] as List)
        .map((c) => c is String ? c : c['id'] as String)
        .toList();

    return Course(id: id, name: yaml['name'], catalogIds: catalogs);
  }
}

class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCorrect': isCorrect,
  };
}

class Question {
  final String id;
  final int number;
  final String text;
  final List<Answer> answers;
  final String category;
  final String? image;

  Question({
    required this.id,
    required this.number,
    required this.text,
    required this.answers,
    required this.category,
    this.image,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'text': text,
    'answers': answers.map((a) => a.toJson()).toList(),
    'category': category,
    if (image != null) 'image': image,
  };
}

class QuestionScraper {
  final String cacheDir = '.cache';

  /// Generate a unique ID for a question based on its content
  String generateQuestionId(int number, String text, String category) {
    final content = '$category-$number-${_normalizeText(text)}';
    final hash = _generateHash(content);
    return 'q_$hash';
  }

  /// Generate a unique ID for an answer based on its content
  String generateAnswerId(String questionId, int index, String text) {
    final content = '$questionId-$index-${_normalizeText(text)}';
    final hash = _generateHash(content);
    return 'a_$hash';
  }

  /// Generate SHA-256 hash and return first 12 characters
  String _generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12);
  }

  /// Normalize text to ensure consistent ID generation
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  Future<void> run() async {
    print('🚀 Starting question scraping...\n');

    // Create necessary directories
    await Directory(cacheDir).create(recursive: true);
    await Directory('.data/catalogs').create(recursive: true);
    await Directory('.data/courses').create(recursive: true);

    // Load manifest
    final manifestFile = File('assets/data/manifest.yaml');
    if (!await manifestFile.exists()) {
      print('❌ Error: manifest.yaml not found');
      exit(1);
    }

    final manifestContent = await manifestFile.readAsString();
    final manifest = loadYaml(manifestContent);

    // Parse catalogs and courses
    final catalogs = <String, Catalog>{};
    final courses = <String, Course>{};

    if (manifest['catalogs'] != null) {
      manifest['catalogs'].forEach((id, data) {
        catalogs[id] = Catalog.fromYaml(id, data);
      });
    }

    if (manifest['courses'] != null) {
      manifest['courses'].forEach((id, data) {
        courses[id] = Course.fromYaml(id, data);
      });
    }

    print(
      '📚 Found ${catalogs.length} catalogs and ${courses.length} courses\n',
    );

    // Scrape each catalog
    for (final catalog in catalogs.values) {
      await scrapeCatalog(catalog);
    }

    // Generate course files
    for (final course in courses.values) {
      await generateCourseFiles(course, catalogs);
    }

    print('\n✅ Scraping completed successfully!');
  }

  Future<void> scrapeCatalog(Catalog catalog) async {
    print('📖 Scraping catalog: ${catalog.name}');
    print('   URL: ${catalog.url}');

    final cacheFile = File('$cacheDir/${catalog.id}.html');
    String htmlContent;

    // Check cache first
    if (await cacheFile.exists()) {
      print('   Using cached HTML');
      htmlContent = await cacheFile.readAsString();
    } else {
      print('   Fetching from web...');
      try {
        final response = await http.get(Uri.parse(catalog.url));
        if (response.statusCode != 200) {
          print('   ❌ Failed to fetch: HTTP ${response.statusCode}');
          return;
        }
        htmlContent = response.body;
        await cacheFile.writeAsString(htmlContent);
        print('   ✓ Fetched and cached');
      } catch (e) {
        print('   ❌ Error fetching: $e');
        return;
      }
    }

    // Parse HTML
    final document = html_parser.parse(htmlContent);
    final questions = parseQuestions(document, catalog.id);

    print('   ✓ Parsed ${questions.length} questions');

    // Save to YAML
    final outputFile = File('.data/catalogs/${catalog.id}.yaml');
    await saveQuestionsToYaml(questions, outputFile, catalog);

    print('   ✓ Saved to ${outputFile.path}\n');
  }

  List<Question> parseQuestions(Document document, String category) {
    final questions = <Question>[];

    // Find all paragraphs that might be questions
    final paragraphs = document.querySelectorAll('p');

    for (int i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      final text = p.text.trim();

      // Check if this looks like a question (starts with number)
      final questionMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(text);
      if (questionMatch == null) continue;

      final questionNum = int.parse(questionMatch.group(1)!);
      final questionText = questionMatch.group(2)!;

      // Look for the next <ol> element with answers
      Element? answerList;
      for (int j = i + 1; j < paragraphs.length && j < i + 5; j++) {
        final nextElement = paragraphs[j].nextElementSibling;
        if (nextElement != null && nextElement.localName == 'ol') {
          if (nextElement.classes.contains('elwisOL-lowerLiteral')) {
            answerList = nextElement;
            break;
          }
        }
      }

      if (answerList == null) {
        // Try finding ol directly after this paragraph
        var sibling = p.nextElementSibling;
        while (sibling != null &&
            sibling.localName != 'ol' &&
            sibling.localName != 'p') {
          sibling = sibling.nextElementSibling;
        }
        if (sibling != null && sibling.localName == 'ol') {
          answerList = sibling;
        }
      }

      if (answerList != null) {
        final answerTexts = answerList
            .querySelectorAll('li')
            .map((li) => li.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        if (answerTexts.length >= 3) {
          // Generate question ID first
          final questionId = generateQuestionId(questionNum, questionText, category);
          
          // Create Answer objects with IDs
          final answers = <Answer>[];
          for (int i = 0; i < answerTexts.length; i++) {
            final answerId = generateAnswerId(questionId, i, answerTexts[i]);
            // First answer is typically the correct one in these exams
            final isCorrect = i == 0;
            answers.add(Answer(
              id: answerId,
              text: answerTexts[i],
              isCorrect: isCorrect,
            ));
          }

          questions.add(
            Question(
              id: questionId,
              number: questionNum,
              text: questionText,
              answers: answers,
              category: category,
            ),
          );
        }
      }
    }

    return questions;
  }

  Future<void> saveQuestionsToYaml(
    List<Question> questions,
    File outputFile,
    Catalog catalog,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('# Questions for ${catalog.name}');
    buffer.writeln('# Source: ${catalog.url}');
    buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('catalog:');
    buffer.writeln('  id: ${catalog.id}');
    buffer.writeln('  name: "${catalog.name}"');
    buffer.writeln('  description: "${catalog.description}"');
    buffer.writeln('  questionCount: ${questions.length}');
    buffer.writeln();
    buffer.writeln('questions:');

    for (final question in questions) {
      buffer.writeln('  - id: ${question.id}');
      buffer.writeln('    number: ${question.number}');
      buffer.writeln('    text: "${question.text.replaceAll('"', '\\"')}"');
      buffer.writeln('    options:');
      for (final answer in question.answers) {
        buffer.writeln('      - id: ${answer.id}');
        buffer.writeln('        text: "${answer.text.replaceAll('"', '\\"')}"');
        buffer.writeln('        isCorrect: ${answer.isCorrect}');
      }
      if (question.image != null) {
        buffer.writeln('    image: "${question.image}"');
      }
      buffer.writeln();
    }

    await outputFile.writeAsString(buffer.toString());
  }

  Future<void> generateCourseFiles(
    Course course,
    Map<String, Catalog> catalogs,
  ) async {
    print('📝 Generating course files for: ${course.name}');

    final courseDir = Directory('.data/courses/${course.id}');
    await courseDir.create(recursive: true);

    // Collect all questions from referenced catalogs
    final allQuestions = <Question>[];
    var questionOffset = 0;

    for (final catalogId in course.catalogIds) {
      final catalogFile = File('.data/catalogs/$catalogId.yaml');
      if (!await catalogFile.exists()) {
        print('   ⚠️  Catalog file not found: $catalogId');
        continue;
      }

      final catalogYaml = loadYaml(await catalogFile.readAsString());
      final questions = catalogYaml['questions'] as List;

      for (final q in questions) {
        // Parse answers from YAML
        final answerList = q['options'] as List? ?? q['answers'] as List;
        final answers = <Answer>[];
        
        if (answerList.first is Map) {
          // New format with Answer objects
          for (final a in answerList) {
            answers.add(Answer(
              id: a['id'],
              text: a['text'],
              isCorrect: a['isCorrect'] ?? false,
            ));
          }
        } else {
          // Legacy format - generate IDs
          final questionId = q['id'] ?? generateQuestionId(
            questionOffset + (q['number'] as int),
            q['text'],
            catalogId,
          );
          for (int i = 0; i < answerList.length; i++) {
            final answerId = generateAnswerId(questionId, i, answerList[i]);
            answers.add(Answer(
              id: answerId,
              text: answerList[i],
              isCorrect: i == 0, // Assume first is correct for legacy
            ));
          }
        }

        allQuestions.add(
          Question(
            id: q['id'] ?? generateQuestionId(
              questionOffset + (q['number'] as int),
              q['text'],
              catalogId,
            ),
            number: questionOffset + (q['number'] as int),
            text: q['text'],
            answers: answers,
            category: catalogId,
            image: q['image'],
          ),
        );
      }

      questionOffset = allQuestions.length;
      print('   ✓ Added ${questions.length} questions from $catalogId');
    }

    // Save combined questions
    final outputFile = File('${courseDir.path}/questions.yaml');
    final buffer = StringBuffer();

    buffer.writeln('# Questions for ${course.name}');
    buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('course: ${course.name}');
    buffer.writeln('version: \'${DateTime.now().year}\'');
    buffer.writeln('source: ELWIS');
    buffer.writeln('metadata:');
    buffer.writeln('  courseId: ${course.id}');
    buffer.writeln('  totalQuestions: ${allQuestions.length}');
    buffer.writeln('  catalogs:');
    for (final catalogId in course.catalogIds) {
      buffer.writeln('    - $catalogId');
    }
    buffer.writeln();
    buffer.writeln('questions:');

    for (final question in allQuestions) {
      buffer.writeln('  - id: ${question.id}');
      buffer.writeln('    number: ${question.number}');
      buffer.writeln('    text: "${question.text.replaceAll('"', '\\"')}"');
      buffer.writeln('    options:');
      for (final answer in question.answers) {
        buffer.writeln('      - id: ${answer.id}');
        buffer.writeln('        text: "${answer.text.replaceAll('"', '\\"')}"');
        buffer.writeln('        isCorrect: ${answer.isCorrect}');
      }
      buffer.writeln('    category: ${question.category}');
      if (question.image != null) {
        buffer.writeln('    image: "${question.image}"');
      }
      buffer.writeln();
    }

    await outputFile.writeAsString(buffer.toString());
    print(
      '   ✓ Saved ${allQuestions.length} questions to ${outputFile.path}\n',
    );
  }
}

void main(List<String> args) async {
  final scraper = QuestionScraper();
  await scraper.run();
}
