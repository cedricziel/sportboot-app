import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/questions_provider.dart';
import 'screens/course_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandler();
  }

  void _setupNotificationHandler() {
    NotificationService().setNotificationTapCallback(() async {
      // Navigate to quiz screen when notification is tapped
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider = Provider.of<QuestionsProvider>(context, listen: false);
        
        // Load all questions if not already loaded
        if (provider.currentQuestions.isEmpty) {
          await provider.loadCourseById(
            StorageService().getSetting('selectedCourseId', defaultValue: 'sbf-see')
          );
        }
        
        // Start a quiz session
        provider.startSession('quiz', 'all');
        
        // Navigate to home screen first, then to quiz
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QuizScreen(),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => QuestionsProvider())],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
        home: const CourseSelectionScreen(),
      ),
    );
  }
}
