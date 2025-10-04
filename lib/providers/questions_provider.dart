import 'package:flutter/widgets.dart';
import '../models/course.dart';
import '../models/course_manifest.dart';
import '../models/question.dart';
import '../models/study_session.dart';
import '../repositories/question_repository.dart';
import '../services/data_loader.dart';
import '../services/migration_service.dart';
import '../services/storage_service.dart';

class QuestionsProvider extends ChangeNotifier {
  Course? _currentCourse;
  List<Question> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  StudySession? _currentSession;
  final StorageService _storage = StorageService();
  final QuestionRepository _repository;
  final MigrationService _migrationService;
  bool _isInitialized = false;

  // Constructor with dependency injection
  QuestionsProvider({
    QuestionRepository? repository,
    MigrationService? migrationService,
  }) : _repository = repository ?? QuestionRepository(),
       _migrationService = migrationService ?? MigrationService();

  // Course management
  String? _selectedCourseId;
  CourseManifest? _selectedCourseManifest;
  Manifest? _manifest;

  bool _isLoading = false;
  String? _error;
  double _migrationProgress = 0.0;
  String _migrationStatus = '';

  // Cache for shuffled questions to maintain consistency
  final Map<String, Question> _shuffledQuestionsCache = {};

  // Getters
  Course? get currentCourse => _currentCourse;
  List<Question> get currentQuestions => _currentQuestions;
  Question? get currentQuestion {
    if (_currentQuestionIndex >= _currentQuestions.length) {
      return null;
    }

    final originalQuestion = _currentQuestions[_currentQuestionIndex];

    // Check if we already have a shuffled version cached
    if (_shuffledQuestionsCache.containsKey(originalQuestion.id)) {
      return _shuffledQuestionsCache[originalQuestion.id];
    }

    // Create and cache a shuffled version
    final shuffledQuestion = originalQuestion.copyWithShuffledOptions();
    _shuffledQuestionsCache[originalQuestion.id] = shuffledQuestion;

    return shuffledQuestion;
  }

  int get currentQuestionIndex => _currentQuestionIndex;
  StudySession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNext => _currentQuestionIndex < _currentQuestions.length - 1;
  bool get hasPrevious => _currentQuestionIndex > 0;
  double get migrationProgress => _migrationProgress;
  String get migrationStatus => _migrationStatus;

  // Course management getters
  String? get selectedCourseId => _selectedCourseId;
  CourseManifest? get selectedCourseManifest => _selectedCourseManifest;
  Manifest? get manifest => _manifest;

  // Initialize storage and load manifest
  Future<void> init() async {
    // Skip if already initialized
    if (_isInitialized) {
      debugPrint('[QuestionsProvider] Already initialized, skipping...');
      return;
    }

    _isLoading = true;
    // Defer the notification to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('[QuestionsProvider] Initializing...');
      await _storage.init();
      debugPrint('[QuestionsProvider] Storage initialized');

      // Perform data migration if needed
      debugPrint('[QuestionsProvider] Starting migration check...');
      await _migrationService.migrateDataIfNeeded(
        onProgress: (progress) {
          _migrationProgress = progress;
          debugPrint(
            '[QuestionsProvider] Migration progress: ${(progress * 100).toInt()}%',
          );
          // Defer the notification to avoid calling it during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        },
        onStatusUpdate: (status) {
          _migrationStatus = status;
          debugPrint('[QuestionsProvider] Migration status: $status');
          // Defer the notification to avoid calling it during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        },
      );
      debugPrint('[QuestionsProvider] Migration completed');

      await loadManifest();
      debugPrint('[QuestionsProvider] Manifest loaded');

      // Restore selected course from storage if available
      final storedCourseId = getStoredCourseId();
      if (storedCourseId != null && _manifest != null) {
        final courseManifest = _manifest!.courses[storedCourseId];
        if (courseManifest != null) {
          _selectedCourseId = storedCourseId;
          _selectedCourseManifest = courseManifest;
        }
      }

      _isInitialized = true;
      debugPrint('[QuestionsProvider] Initialization complete');
    } catch (e) {
      _error = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      // Defer the notification to avoid calling it during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Load manifest
  Future<void> loadManifest() async {
    try {
      _manifest = await DataLoader.loadManifest();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load manifest: $e';
      notifyListeners();
    }
  }

  // Set selected course
  void setSelectedCourse(String courseId, CourseManifest courseManifest) {
    _selectedCourseId = courseId;
    _selectedCourseManifest = courseManifest;
    _storage.setSetting('selectedCourseId', courseId);
    notifyListeners();
  }

  // Get selected course from storage
  String? getStoredCourseId() {
    return _storage.getSetting('selectedCourseId') as String?;
  }

  // Load all questions from database for the selected course
  Future<void> loadAllQuestions() async {
    if (_selectedCourseManifest == null) {
      _error = 'Kein Kurs ausgewählt';
      notifyListeners();
      return;
    }

    // Load all questions from the catalogs that belong to this course
    await _loadQuestionsFromDatabase(
      () => _repository.getQuestionsByCatalogs(
        _selectedCourseManifest!.catalogIds,
      ),
    );
  }

  // Load questions by category
  Future<void> loadQuestionsByCategory(String category) async {
    await _loadQuestionsFromDatabase(
      () => _repository.getQuestionsByCategory(category),
    );
  }

  // Load bookmarked questions from database
  Future<void> loadBookmarkedQuestions() async {
    await _loadQuestionsFromDatabase(
      () => _repository.getBookmarkedQuestions(),
    );
  }

  // Load incorrect questions from database
  Future<void> loadIncorrectQuestions() async {
    await _loadQuestionsFromDatabase(() => _repository.getIncorrectQuestions());
  }

  // Generic method to load questions from database
  Future<void> _loadQuestionsFromDatabase(
    Future<List<Question>> Function() loader,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[QuestionsProvider] Loading questions from database...');
      _currentQuestions = await loader();
      debugPrint(
        '[QuestionsProvider] Loaded ${_currentQuestions.length} questions',
      );
      _currentQuestionIndex = 0;

      // Clear the shuffled questions cache when loading new questions
      _shuffledQuestionsCache.clear();

      // Apply shuffle if enabled (shuffles the order of questions, not their answers)
      if (_storage.getSetting('shuffleQuestions', defaultValue: false)) {
        _currentQuestions.shuffle();
        debugPrint('[QuestionsProvider] Shuffled question order');
      }

      _error = null;
    } catch (e) {
      debugPrint('[QuestionsProvider] Error loading questions: $e');
      _error = 'Failed to load questions: $e';
      _currentQuestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy methods for backward compatibility
  Future<void> loadBasisfragen() async {
    await loadQuestionsByCategory('basisfragen');
  }

  Future<void> loadSpezifischeSee() async {
    await loadQuestionsByCategory('spezifische-see');
  }

  Future<void> loadRandomQuestions(int count) async {
    // Require a selected course
    if (_selectedCourseManifest == null) {
      _error = 'Bitte wähle zuerst einen Kurs aus';
      notifyListeners();
      return;
    }

    // Load all questions from the selected course
    await loadAllQuestions();

    if (_currentQuestions.isEmpty) {
      _error = 'Keine Fragen im ausgewählten Kurs verfügbar';
      notifyListeners();
      return;
    }

    if (count > _currentQuestions.length) {
      // Not enough questions in the selected course
      _error =
          'Nicht genügend Fragen im ausgewählten Kurs (${_currentQuestions.length} verfügbar)';
      notifyListeners();
      return;
    }

    // Shuffle and take the requested number of questions
    _currentQuestions.shuffle();
    if (count < _currentQuestions.length) {
      _currentQuestions = _currentQuestions.take(count).toList();
    }
    notifyListeners();
  }

  Future<void> loadCategory(String category) async {
    // Find the category in the selected course manifest
    if (_selectedCourseManifest == null) {
      _error = 'Kein Kurs ausgewählt';
      notifyListeners();
      return;
    }

    final categoryInfo = _selectedCourseManifest!.categories.firstWhere(
      (c) => c.id == category,
      orElse: () =>
          throw Exception('Category $category not found in course manifest'),
    );

    // Load questions from all catalogs referenced by this category
    await _loadQuestionsFromDatabase(
      () => _repository.getQuestionsByCatalogs(categoryInfo.catalogRefs),
    );
  }

  // Filter questions by bookmarks (now loads from database)
  Future<void> filterByBookmarks() async {
    await loadBookmarkedQuestions();
  }

  // Filter questions by incorrect answers (now loads from database)
  Future<void> filterByIncorrect() async {
    await loadIncorrectQuestions();
  }

  // Navigation methods
  void nextQuestion() {
    if (hasNext) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (hasPrevious) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _currentQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  // Start a new study session
  void startSession(String mode, String category) {
    _currentSession = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      questionIds: _currentQuestions.map((q) => q.id).toList(),
      answers: {},
      timeSpent: {},
      category: category,
      mode: mode,
    );
    notifyListeners();
  }

  // Answer a question and update database
  Future<void> answerQuestion(int answerIndex) async {
    if (_currentSession == null || currentQuestion == null) return;

    final isCorrect = currentQuestion!.isAnswerCorrect(answerIndex);

    // Update session with new answer
    final updatedAnswers = Map<String, bool>.from(_currentSession!.answers);
    updatedAnswers[currentQuestion!.id] = isCorrect;

    _currentSession = _currentSession!.copyWith(answers: updatedAnswers);

    // Update progress in database
    await _repository.updateProgress(
      questionId: currentQuestion!.id,
      isCorrect: isCorrect,
    );

    notifyListeners();
  }

  // End current session
  void endSession() {
    _currentSession = null;
    notifyListeners();
  }

  // Bookmark operations
  Future<void> toggleBookmark([String? questionId]) async {
    final id = questionId ?? currentQuestion?.id;
    if (id == null) return;

    final bookmarks = await _repository.getBookmarkedQuestionIds();

    if (bookmarks.contains(id)) {
      await _repository.removeBookmark(id);
    } else {
      await _repository.addBookmark(id);
    }

    notifyListeners();
  }

  Future<bool> isBookmarked(String questionId) async {
    final bookmarks = await _repository.getBookmarkedQuestionIds();
    return bookmarks.contains(questionId);
  }

  Future<bool> isCurrentQuestionBookmarked() async {
    if (currentQuestion == null) return false;
    return isBookmarked(currentQuestion!.id);
  }

  // Get counts for UI
  Future<int> getBookmarkCount() async {
    return await _repository.getBookmarkCount();
  }

  Future<int> getIncorrectCount() async {
    return await _repository.getIncorrectCount();
  }

  // Get overall progress
  Future<Map<String, dynamic>> getProgress() async {
    return await _repository.getProgress();
  }

  // Get session stats
  Map<String, dynamic> getSessionStats() {
    if (_currentSession == null) {
      return {'correct': 0, 'incorrect': 0, 'total': 0, 'unanswered': 0};
    }

    return {
      'correct': _currentSession!.correctAnswers,
      'incorrect': _currentSession!.incorrectAnswers,
      'total': _currentSession!.totalQuestions,
      'unanswered': _currentSession!.unanswered,
    };
  }

  // Reset progress
  Future<void> resetProgress() async {
    _currentQuestionIndex = 0;
    _currentSession = null;
    // Could also clear database progress if needed
    notifyListeners();
  }

  // Settings
  bool get shuffleEnabled =>
      _storage.getSetting('shuffleQuestions', defaultValue: false);

  void toggleShuffle() {
    final current = shuffleEnabled;
    _storage.setSetting('shuffleQuestions', !current);

    if (!current && _currentQuestions.isNotEmpty) {
      _currentQuestions.shuffle();
    }

    notifyListeners();
  }
}
