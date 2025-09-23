import 'package:flutter/foundation.dart';
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
  final QuestionRepository _repository = QuestionRepository();
  final MigrationService _migrationService = MigrationService();

  // Course management
  String? _selectedCourseId;
  CourseManifest? _selectedCourseManifest;
  Manifest? _manifest;

  bool _isLoading = false;
  String? _error;
  double _migrationProgress = 0.0;
  String _migrationStatus = '';

  // Getters
  Course? get currentCourse => _currentCourse;
  List<Question> get currentQuestions => _currentQuestions;
  Question? get currentQuestion =>
      _currentQuestionIndex < _currentQuestions.length
      ? _currentQuestions[_currentQuestionIndex]
      : null;
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
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.init();
      
      // Perform data migration if needed
      await _migrationService.migrateDataIfNeeded(
        onProgress: (progress) {
          _migrationProgress = progress;
          notifyListeners();
        },
        onStatusUpdate: (status) {
          _migrationStatus = status;
          notifyListeners();
        },
      );

      await loadManifest();

      // Restore selected course from storage if available
      final storedCourseId = getStoredCourseId();
      if (storedCourseId != null && _manifest != null) {
        final courseManifest = _manifest!.courses[storedCourseId];
        if (courseManifest != null) {
          _selectedCourseId = storedCourseId;
          _selectedCourseManifest = courseManifest;
        }
      }
    } catch (e) {
      _error = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // Load all questions from database
  Future<void> loadAllQuestions() async {
    await _loadQuestionsFromDatabase(() => _repository.getAllQuestions());
  }

  // Load questions by category from database
  Future<void> loadCourseById(String courseId) async {
    await _loadQuestionsFromDatabase(() => _repository.getQuestionsByCourse(courseId));
  }

  // Load questions by category
  Future<void> loadQuestionsByCategory(String category) async {
    await _loadQuestionsFromDatabase(() => _repository.getQuestionsByCategory(category));
  }

  // Load bookmarked questions from database
  Future<void> loadBookmarkedQuestions() async {
    await _loadQuestionsFromDatabase(() => _repository.getBookmarkedQuestions());
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
      _currentQuestions = await loader();
      _currentQuestionIndex = 0;

      // Apply shuffle if enabled
      if (_storage.getSetting('shuffleQuestions', defaultValue: false)) {
        _currentQuestions.shuffle();
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load questions: $e';
      _currentQuestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy methods for backward compatibility
  Future<void> loadBasisfragen() async {
    await loadQuestionsByCategory('Basisfragen');
  }

  Future<void> loadSpezifischeSee() async {
    await loadQuestionsByCategory('Spezifische Fragen See');
  }

  Future<void> loadRandomQuestions(int count) async {
    await loadAllQuestions();
    if (_currentQuestions.isNotEmpty && count < _currentQuestions.length) {
      _currentQuestions.shuffle();
      _currentQuestions = _currentQuestions.take(count).toList();
      notifyListeners();
    }
  }

  Future<void> loadCategory(String category) async {
    await loadQuestionsByCategory(category);
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
    
    _currentSession = _currentSession!.copyWith(
      answers: updatedAnswers,
    );

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
      return {
        'correct': 0,
        'incorrect': 0,
        'total': 0,
      };
    }
    
    return {
      'correct': _currentSession!.correctAnswers,
      'incorrect': _currentSession!.incorrectAnswers,
      'total': _currentSession!.totalQuestions,
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