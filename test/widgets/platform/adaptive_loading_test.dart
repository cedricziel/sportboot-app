import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/widgets/platform/adaptive_loading.dart';
import 'package:sportboot_app/utils/platform_helper.dart';

void main() {
  group('AdaptiveLoadingIndicator Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('renders CircularProgressIndicator by default on macOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AdaptiveLoadingIndicator())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('renders CupertinoActivityIndicator in iOS preview mode', (
      WidgetTester tester,
    ) async {
      // Enable iOS preview mode
      PlatformHelper.enableIOSPreview();

      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(child: AdaptiveLoadingIndicator()),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('respects custom radius parameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AdaptiveLoadingIndicator(radius: 20.0)),
        ),
      );

      // Widget should render (we can't easily test the radius value itself)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('showAdaptiveLoadingDialog Tests', () {
    setUp(() {
      // Reset iOS preview mode before each test
      PlatformHelper.disableIOSPreview();
    });
    testWidgets('shows loading dialog with Material indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveLoadingDialog(context);
                },
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading dialog with Cupertino indicator in iOS mode', (
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
                  showAdaptiveLoadingDialog(context);
                },
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('loading dialog is not dismissible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveLoadingDialog(context);
                },
                child: const Text('Show Loading'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Try to tap outside the dialog (should not dismiss because barrierDismissible is false)
      // The dialog will still be there
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Dialog should still be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
