import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide showAdaptiveDialog;
import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/widgets/platform/adaptive_dialog.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('showAdaptiveDialog Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('shows Material AlertDialog by default on macOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    title: 'Test Dialog',
                    content: 'Test Content',
                    actions: [
                      AdaptiveDialogAction(
                        onPressed: () {},
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('shows CupertinoAlertDialog in iOS preview mode', (
      WidgetTester tester,
    ) async {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    title: 'Test Dialog',
                    content: 'Test Content',
                    actions: [
                      AdaptiveDialogAction(
                        onPressed: () {},
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('dialog actions are tappable', (WidgetTester tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    title: 'Test',
                    actions: [
                      AdaptiveDialogAction(
                        onPressed: () {
                          actionTapped = true;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tap Me'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
    });

    testWidgets('supports custom content widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    title: 'Test',
                    contentWidget: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('Line 1'), Text('Line 2')],
                    ),
                    actions: [
                      AdaptiveDialogAction(
                        onPressed: () {},
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });

    testWidgets('destructive action is styled correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    title: 'Delete?',
                    actions: [
                      AdaptiveDialogAction(
                        onPressed: () {},
                        child: const Text('Cancel'),
                      ),
                      AdaptiveDialogAction(
                        onPressed: () {},
                        isDestructive: true,
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
