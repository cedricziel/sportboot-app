import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportboot_app/models/course.dart';
import 'package:sportboot_app/providers/questions_provider.dart';
import 'package:sportboot_app/services/storage_service.dart';

void main() {
  group('Course Loading Tests', () {
    late QuestionsProvider provider;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      provider = QuestionsProvider();
      // Initialize storage
      await StorageService().init();
    });

    test('Course model handles both YAML formats correctly', () {
      // Test new format with course as string
      final newFormatMap = {
        'course': 'Sportbootführerschein See',
        'version': '2024',
        'source': 'ELWIS',
        'questions': [
          {
            'id': 'q_test1',
            'number': 1,
            'text': 'Test question?',
            'options': [
              {'id': 'a_1', 'text': 'Answer 1', 'isCorrect': true},
              {'id': 'a_2', 'text': 'Answer 2', 'isCorrect': false},
            ],
            'category': 'test',
            'assets': [],
          }
        ],
      };
      
      final newFormatCourse = Course.fromMap(newFormatMap);
      expect(newFormatCourse.name, 'Sportbootführerschein See');
      expect(newFormatCourse.version, '2024');
      expect(newFormatCourse.source, 'ELWIS');
      expect(newFormatCourse.questions.length, 1);
      
      // Test legacy format with course as nested object
      final legacyFormatMap = {
        'course': {
          'id': 'sbf-see',
          'name': 'Sportbootführerschein See',
          'totalQuestions': 285,
        },
        'questions': [
          {
            'id': 'q_test2',
            'number': 1,
            'text': 'Legacy question?',
            'options': [
              {'id': 'a_3', 'text': 'Answer 3', 'isCorrect': true},
            ],
            'category': 'legacy',
            'assets': [],
          }
        ],
      };
      
      final legacyCourse = Course.fromMap(legacyFormatMap);
      expect(legacyCourse.name, 'Sportbootführerschein See');
      expect(legacyCourse.version, '2024'); // Should use default
      expect(legacyCourse.source, 'ELWIS'); // Should use default
      expect(legacyCourse.questions.length, 1);
    });

    test('Provider initializes and restores selected course from storage', () async {
      // Set a course ID in storage
      final storage = StorageService();
      await storage.init();
      storage.setSetting('selectedCourseId', 'sbf-see');
      
      // Initialize provider
      final testProvider = QuestionsProvider();
      await testProvider.init();
      
      // The course manifest should be loaded if the manifest contains it
      if (testProvider.manifest != null && 
          testProvider.manifest!.courses.containsKey('sbf-see')) {
        expect(testProvider.selectedCourseId, 'sbf-see');
        expect(testProvider.selectedCourseManifest, isNotNull);
        expect(testProvider.selectedCourseManifest!.id, 'sbf-see');
      }
    });

    test('loadRandomQuestions loads correct number of questions', () async {
      await provider.init();
      
      // Set a course
      if (provider.manifest != null && 
          provider.manifest!.courses.isNotEmpty) {
        final firstCourse = provider.manifest!.courses.entries.first;
        provider.setSelectedCourse(firstCourse.key, firstCourse.value);
        
        // Load random questions
        await provider.loadRandomQuestions(14);
        
        // Should have exactly 14 questions
        expect(provider.currentQuestions.length, 14);
        expect(provider.currentQuestionIndex, 0);
        
        // All questions should have valid IDs
        for (final question in provider.currentQuestions) {
          expect(question.id, isNotEmpty);
          expect(question.id, startsWith('q_'));
          
          // All answers should have IDs
          for (final option in question.options) {
            expect(option.id, isNotEmpty);
            expect(option.id, startsWith('a_'));
          }
        }
      }
    });

    test('Category loading works correctly', () async {
      await provider.init();
      
      // Set SBF-See course
      if (provider.manifest != null && 
          provider.manifest!.courses.containsKey('sbf-see')) {
        final sbfSeeCourse = provider.manifest!.courses['sbf-see']!;
        provider.setSelectedCourse('sbf-see', sbfSeeCourse);
        
        // Load a specific category
        await provider.loadCategory('basics');
        
        // Should have questions from the basics category
        expect(provider.currentQuestions, isNotEmpty);
        
        // Load all questions
        await provider.loadAllQuestions();
        final totalQuestions = provider.currentQuestions.length;
        expect(totalQuestions, greaterThan(0));
        
        // Loading bookmarks should filter
        await provider.loadAllQuestions();
        provider.filterByBookmarks();
        // Initially no bookmarks, so should be empty
        expect(provider.currentQuestions.isEmpty, true);
      }
    });

    test('Question and Answer IDs are unique and consistent', () async {
      await provider.init();
      
      if (provider.manifest != null && 
          provider.manifest!.courses.isNotEmpty) {
        final firstCourse = provider.manifest!.courses.entries.first;
        provider.setSelectedCourse(firstCourse.key, firstCourse.value);
        
        await provider.loadAllQuestions();
        
        final questionIds = <String>{};
        final answerIds = <String>{};
        
        for (final question in provider.currentQuestions) {
          // Check question ID uniqueness
          expect(questionIds.contains(question.id), false,
              reason: 'Duplicate question ID found: ${question.id}');
          questionIds.add(question.id);
          
          // Check answer ID uniqueness
          for (final option in question.options) {
            expect(answerIds.contains(option.id), false,
                reason: 'Duplicate answer ID found: ${option.id}');
            answerIds.add(option.id);
          }
        }
      }
    });
  });
}