import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../models/study_session.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';

class QuestionsProvider extends ChangeNotifier {
  Course? _currentCourse;
  List<Question> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  StudySession? _currentSession;
  final StorageService _storage = StorageService();
  
  bool _isLoading = false;
  String? _error;

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

  // Initialize storage
  Future<void> init() async {
    await _storage.init();
  }

  // Load course data
  Future<void> loadCourse(String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCourse = await DataLoader.loadCourse(filename);
      _currentQuestions = List.from(_currentCourse!.questions);
      _currentQuestionIndex = 0;
      
      // Apply shuffle if enabled
      if (_storage.getSetting('shuffleQuestions', defaultValue: false)) {
        _currentQuestions.shuffle();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all questions
  Future<void> loadAllQuestions() async {
    await loadCourse('all_questions.yaml');
  }

  // Load questions by category
  Future<void> loadCategory(String category) async {
    if (category == 'basisfragen') {
      await loadCourse('basisfragen.yaml');
    } else if (category == 'spezifische-see') {
      await loadCourse('spezifische-see.yaml');
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

  // End current session
  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
      );
      _storage.incrementStatistic('studySessions');
      _storage.updateStudyStreak();
    }
    notifyListeners();
  }

  // Answer current question
  void answerQuestion(int selectedIndex) {
    if (currentQuestion == null || _currentSession == null) return;
    
    final isCorrect = currentQuestion!.isAnswerCorrect(selectedIndex);
    
    // Update session
    _currentSession!.answers[currentQuestion!.id] = isCorrect;
    
    // Update storage
    _storage.saveQuestionProgress(
      currentQuestion!.id,
      isCorrect,
      (_storage.getProgress()[currentQuestion!.id]?['attempts'] ?? 0) + 1,
    );
    
    // Update statistics
    _storage.incrementStatistic('totalQuestions');
    if (isCorrect) {
      _storage.incrementStatistic('correctAnswers');
    } else {
      _storage.incrementStatistic('incorrectAnswers');
    }
    
    notifyListeners();
  }

  // Navigation
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

  // Bookmarks
  void toggleBookmark() {
    if (currentQuestion != null) {
      _storage.toggleBookmark(currentQuestion!.id);
      notifyListeners();
    }
  }

  bool isCurrentQuestionBookmarked() {
    if (currentQuestion == null) return false;
    return _storage.isBookmarked(currentQuestion!.id);
  }

  // Filter questions
  void filterByBookmarks() {
    if (_currentCourse == null) return;
    
    final bookmarks = _storage.getBookmarks();
    _currentQuestions = _currentCourse!.questions
        .where((q) => bookmarks.contains(q.id))
        .toList();
    _currentQuestionIndex = 0;
    notifyListeners();
  }

  void filterByIncorrect() {
    if (_currentCourse == null) return;
    
    final progress = _storage.getProgress();
    _currentQuestions = _currentCourse!.questions
        .where((q) => progress[q.id]?['correct'] == false)
        .toList();
    _currentQuestionIndex = 0;
    notifyListeners();
  }

  void resetFilters() {
    if (_currentCourse != null) {
      _currentQuestions = List.from(_currentCourse!.questions);
      _currentQuestionIndex = 0;
      notifyListeners();
    }
  }

  // Progress tracking
  double getProgress() {
    if (_currentQuestions.isEmpty) return 0;
    return (_currentQuestionIndex + 1) / _currentQuestions.length;
  }

  Map<String, int> getSessionStats() {
    if (_currentSession == null) return {'correct': 0, 'incorrect': 0, 'unanswered': 0};
    
    return {
      'correct': _currentSession!.correctAnswers,
      'incorrect': _currentSession!.incorrectAnswers,
      'unanswered': _currentSession!.unanswered,
    };
  }
}