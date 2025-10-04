import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/questions_provider.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService().init();

  // Initialize notification service
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();
    _setupNotificationHandler();
  }

  void _setupNotificationHandler() {
    NotificationService().setNotificationTapCallback(() async {
      // Navigate to quiz screen when notification is tapped
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        final provider = Provider.of<QuestionsProvider>(context, listen: false);

        // Load all questions if not already loaded
        if (provider.currentQuestions.isEmpty) {
          await provider.loadCourseById(
            StorageService().getSetting(
              'selectedCourseId',
              defaultValue: 'sbf-see',
            ),
          );
        }

        // Start a quiz session
        provider.startSession('quiz', 'all');

        // Navigate to home screen first, then to quiz
        if (context.mounted) {
          context.go(AppRoutes.home);
          context.push(AppRoutes.quiz);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => QuestionsProvider())],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'SBF-See Lernkarten',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
