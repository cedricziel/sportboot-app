import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportboot_app/main.dart';

void main() {
  group('App Widget Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({'selectedCourseId': 'sbf-see'});
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // App should build without throwing errors
      expect(tester.takeException(), isNull);
    });
  });
}
