import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import 'course_selection_screen.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<QuestionsProvider>(context, listen: false);
    await provider.init();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CourseSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Consumer<QuestionsProvider>(
            builder: (context, provider, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                        Icons.sailing,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      .animate(
                        onPlay: (controller) => controller.repeat(
                          // Only repeat in non-test environments
                          reverse: true,
                        ),
                      )
                      .shimmer(
                        duration: 2.seconds,
                        delay: Duration.zero,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                  const SizedBox(height: 40),
                  Text(
                    'SBF-See Lernkarten',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (provider.migrationStatus.isNotEmpty) ...[
                    Text(
                      provider.migrationStatus,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: 250,
                    child: LinearProgressIndicator(
                      value: provider.migrationProgress > 0
                          ? provider.migrationProgress
                          : null,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (provider.migrationProgress > 0)
                    Text(
                      '${(provider.migrationProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
