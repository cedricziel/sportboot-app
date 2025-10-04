import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/course_manifest.dart';
import '../providers/questions_provider.dart';
import '../router/app_router.dart';
import '../services/data_loader.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  Manifest? _manifest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await DataLoader.loadManifest();
      setState(() {
        _manifest = manifest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wähle deinen Kurs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Kurse',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadManifest();
              },
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_manifest == null || _manifest!.courses.isEmpty) {
      return const Center(child: Text('Keine Kurse verfügbar'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verfügbare Kurse',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle einen Kurs aus, um mit dem Lernen zu beginnen',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _manifest!.courses.length,
              itemBuilder: (context, index) {
                final courseId = _manifest!.courses.keys.elementAt(index);
                final course = _manifest!.courses[courseId]!;
                return _buildCourseCard(context, courseId, course);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    String courseId,
    CourseManifest course,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectCourse(context, courseId, course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _getColorForCourse(
                        courseId,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        course.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.shortName,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getColorForCourse(courseId),
                            fontWeight: FontWeight.w600,
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${course.totalQuestions} Fragen',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.folder_outlined,
                    '${course.catalogIds.length} Kataloge',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.category_outlined,
                    '${course.categories.length} Kategorien',
                  ),
                  if (course.examConfig != null) ...[
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.quiz_outlined, 'Prüfung verfügbar'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getColorForCourse(String courseId) {
    switch (courseId) {
      case 'sbf-see':
        return Colors.blue;
      case 'sbf-binnen':
        return Colors.teal;
      case 'sbf-binnen-segeln':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  Future<void> _selectCourse(
    BuildContext context,
    String courseId,
    CourseManifest course,
  ) async {
    // Store selected course in provider
    final provider = context.read<QuestionsProvider>();
    provider.setSelectedCourse(courseId, course);

    // Navigate to home screen
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}
