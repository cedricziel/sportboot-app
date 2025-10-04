import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/widgets/platform/adaptive_scaffold.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('AdaptiveScaffold Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('renders Material Scaffold by default on macOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffold(title: Text('Test'), body: Text('Content')),
        ),
      );

      // Should render Material Scaffold (not Cupertino)
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CupertinoPageScaffold), findsNothing);
    });

    testWidgets('renders CupertinoPageScaffold in iOS preview mode', (
      WidgetTester tester,
    ) async {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      await tester.pumpWidget(
        const CupertinoApp(
          home: AdaptiveScaffold(title: Text('Test'), body: Text('Content')),
        ),
      );

      // Should render Cupertino scaffold
      expect(find.byType(CupertinoPageScaffold), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders title in navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffold(
            title: Text('Test Title'),
            body: Text('Content'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders actions in navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            title: const Text('Test'),
            body: const Text('Content'),
            actions: [
              IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders body content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffold(body: Text('Test Body Content')),
        ),
      );

      expect(find.text('Test Body Content'), findsOneWidget);
    });
  });
}
