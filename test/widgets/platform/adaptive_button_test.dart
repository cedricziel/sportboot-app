import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/widgets/platform/adaptive_button.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('AdaptiveButton Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('renders ElevatedButton by default on macOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(CupertinoButton), findsNothing);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('renders CupertinoButton in iOS preview mode', (
      WidgetTester tester,
    ) async {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: AdaptiveButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('button tap triggers callback', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('disabled button does not trigger callback', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(onPressed: null, child: Text('Disabled')),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('AdaptiveTextButton Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('renders TextButton by default on macOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveTextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);
    });

    testWidgets('renders CupertinoButton in iOS preview mode', (
      WidgetTester tester,
    ) async {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: AdaptiveTextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);
    });
  });
}
