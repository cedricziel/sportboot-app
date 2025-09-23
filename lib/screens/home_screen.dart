import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'course_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider and load course info
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<QuestionsProvider>();
      await provider.init();

      // Check if a course is selected
      final storedCourseId = provider.getStoredCourseId();
      if (storedCourseId == null && mounted) {
        // No course selected, navigate to course selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CourseSelectionScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestionsProvider>();
    final courseManifest = provider.selectedCourseManifest;
    final courseTitle = courseManifest?.shortName ?? 'Lernkarten';

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Kurs wechseln',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CourseSelectionScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<QuestionsProvider>(
                  builder: (context, provider, _) {
                    final courseManifest = provider.selectedCourseManifest;
                    final courseName =
                        courseManifest?.name ?? 'Kein Kurs ausgewählt';
                    final courseIcon = courseManifest?.icon ?? '📚';

                    // Get total question count from manifest if available
                    final questionCount = courseManifest?.totalQuestions ?? 0;

                    return Column(
                      children: [
                        Text(courseIcon, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$questionCount Fragen',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Wähle eine Kategorie:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<QuestionsProvider>(
                builder: (context, provider, _) {
                  final courseManifest = provider.selectedCourseManifest;

                  if (courseManifest == null) {
                    return const Center(
                      child: Text('Bitte wähle einen Kurs aus'),
                    );
                  }

                  return ListView(
                    children: [
                      _buildQuickQuizCard(context),
                      const SizedBox(height: 12),
                      // Build category cards dynamically from course manifest
                      ...courseManifest.categories.map((category) {
                        // Map category types to icons and colors
                        IconData icon;
                        Color color;
                        String subtitle;

                        switch (category.type ?? category.id) {
                          case 'all':
                            icon = Icons.list_alt;
                            color = Colors.purple;
                            subtitle = category.description;
                            break;
                          case 'basics':
                          case 'basisfragen':
                            icon = Icons.foundation;
                            color = Colors.blue;
                            subtitle = category.description;
                            break;
                          case 'bookmarks':
                            icon = Icons.bookmark;
                            color = Colors.orange;
                            subtitle = 'Markierte Fragen';
                            break;
                          case 'incorrect':
                            icon = Icons.close_rounded;
                            color = Colors.red;
                            subtitle = 'Zur Wiederholung';
                            break;
                          default:
                            // For specific categories
                            if (category.id.contains('segeln') ||
                                category.id.contains('sail')) {
                              icon = Icons.sailing;
                              color = Colors.teal;
                            } else if (category.id.contains('see') ||
                                category.id.contains('sea')) {
                              icon = Icons.waves;
                              color = Colors.cyan;
                            } else if (category.id.contains('binnen')) {
                              icon = Icons.water;
                              color = Colors.lightBlue;
                            } else {
                              icon = Icons.quiz;
                              color = Colors.indigo;
                            }
                            subtitle = category.description;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildCategoryCard(
                            context,
                            category.name,
                            subtitle,
                            icon,
                            color,
                            category.id,
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuizCard(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () async {
          await _loadQuestionsAndNavigate(
            context,
            'quick_quiz',
            'quiz',
            const QuizScreen(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schnell-Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '14 zufällige Fragen',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Teste dein Wissen in 5 Minuten',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NEU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String category,
  ) {
    return Card(
      child: InkWell(
        onTap: () => _showModeSelection(context, category, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeSelection(BuildContext context, String category, String title) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.style, color: Colors.blue),
                title: const Text('Lernkarten'),
                subtitle: const Text('Frage und Antwort umdrehen'),
                onTap: () async {
                  Navigator.pop(context);
                  await _loadQuestionsAndNavigate(
                    context,
                    category,
                    'flashcard',
                    const FlashcardScreen(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.green),
                title: const Text('Quiz-Modus'),
                subtitle: const Text('Multiple-Choice mit Bewertung'),
                onTap: () async {
                  Navigator.pop(context);
                  await _loadQuestionsAndNavigate(
                    context,
                    category,
                    'quiz',
                    const QuizScreen(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadQuestionsAndNavigate(
    BuildContext context,
    String category,
    String mode,
    Widget screen,
  ) async {
    final provider = context.read<QuestionsProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // Load questions based on category
      if (category == 'quick_quiz') {
        await provider.loadRandomQuestions(14);
      } else if (category == 'bookmarks') {
        await provider.loadAllQuestions();
        provider.filterByBookmarks();
      } else if (category == 'incorrect') {
        await provider.loadAllQuestions();
        provider.filterByIncorrect();
      } else if (category == 'all' || category == 'all_questions') {
        await provider.loadAllQuestions();
      } else {
        // Load category from course manifest
        await provider.loadCategory(category);
      }

      provider.startSession(mode, category);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
    }
  }
}
