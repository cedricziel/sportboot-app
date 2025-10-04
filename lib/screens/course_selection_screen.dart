import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/course_manifest.dart';
import '../providers/questions_provider.dart';
import '../router/app_router.dart';
import '../services/data_loader.dart';
import '../widgets/platform/adaptive_scaffold.dart';
import '../widgets/platform/adaptive_card.dart';
import '../widgets/platform/adaptive_button.dart';
import '../utils/platform_helper.dart';

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
    return AdaptiveScaffold(
      title: const Text('Wähle deinen Kurs'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: PlatformHelper.useIOSStyle
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformHelper.useIOSStyle
                  ? CupertinoIcons.exclamationmark_circle
                  : Icons.error_outline,
              size: 64,
              color: PlatformHelper.useIOSStyle
                  ? CupertinoColors.systemRed
                  : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Kurse',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AdaptiveButton(
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
    final color = _getColorForCourse(courseId);
    final badgeColor = PlatformHelper.useIOSStyle
        ? CupertinoColors.systemBlue
        : Colors.blue;
    final textColor = PlatformHelper.useIOSStyle
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Colors.grey[600];

    return AdaptiveCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      onTap: () => _selectCourse(context, courseId, course),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                        color: color,
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
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${course.totalQuestions} Fragen',
                  style: TextStyle(
                    color: badgeColor,
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
            style: TextStyle(fontSize: 14, color: textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                PlatformHelper.useIOSStyle
                    ? CupertinoIcons.folder
                    : Icons.folder_outlined,
                '${course.catalogIds.length} Kataloge',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                PlatformHelper.useIOSStyle
                    ? CupertinoIcons.square_grid_2x2
                    : Icons.category_outlined,
                '${course.categories.length} Kategorien',
              ),
              if (course.examConfig != null) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  PlatformHelper.useIOSStyle
                      ? CupertinoIcons.question_circle
                      : Icons.quiz_outlined,
                  'Prüfung verfügbar',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final chipColor = PlatformHelper.useIOSStyle
        ? CupertinoColors.secondaryLabel
        : Colors.grey[600];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: chipColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: chipColor)),
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
