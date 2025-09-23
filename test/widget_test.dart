import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportboot_app/main.dart';
import 'package:sportboot_app/services/database_helper.dart';
import 'package:sportboot_app/repositories/question_repository.dart';
import 'helpers/test_database_helper.dart';

void main() {
  group('App Widget Tests', () {
    late DatabaseHelper databaseHelper;
    late QuestionRepository repository;
    
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize test database
      await TestDatabaseHelper.initializeTestDatabase();
      
      databaseHelper = DatabaseHelper.instance;
      repository = QuestionRepository();
    });

    setUp(() async {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({'selectedCourseId': 'sbf-see'});
      
      // Setup test database with some questions
      await databaseHelper.clearDatabase();
      final testQuestions = TestDatabaseHelper.generateTestQuestions(
        count: 10,
        courseId: 'sbf-see',
        category: 'Test',
      );
      await repository.insertQuestions(testQuestions, 'sbf-see');
    });
    
    tearDown(() async {
      await databaseHelper.close();
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // App should build without throwing errors
      expect(tester.takeException(), isNull);
      
      // The app should initially show migration screen
      await tester.pump();
      
      // Then navigate to course selection
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
