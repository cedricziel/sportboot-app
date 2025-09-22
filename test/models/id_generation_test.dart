import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/models/question.dart';
import 'package:sportboot_app/models/answer_option.dart';

void main() {
  group('ID Generation Tests', () {
    test('Question model handles IDs correctly', () {
      // Test new format with options
      final questionMap = {
        'id': 'q_test123',
        'number': 1,
        'text': 'Test question?',
        'options': [
          {'id': 'a_answer1', 'text': 'Answer 1', 'isCorrect': true},
          {'id': 'a_answer2', 'text': 'Answer 2', 'isCorrect': false},
        ],
        'category': 'test',
      };

      final question = Question.fromMap(questionMap);

      expect(question.id, 'q_test123');
      expect(question.options.length, 2);
      expect(question.options[0].id, 'a_answer1');
      expect(question.options[0].isCorrect, true);
      expect(question.options[1].id, 'a_answer2');
      expect(question.options[1].isCorrect, false);
    });

    test('Question model handles legacy format', () {
      // Test legacy format with simple answers array
      final legacyMap = {
        'id': 'q_legacy',
        'number': 2,
        'question': 'Legacy question?',
        'answers': ['Answer A', 'Answer B', 'Answer C'],
        'category': 'legacy',
      };

      final question = Question.fromMap(legacyMap);

      expect(question.id, 'q_legacy');
      expect(question.options.length, 3);
      // Should generate IDs for legacy answers
      expect(question.options[0].id, startsWith('a_legacy_'));
      expect(question.options[0].text, 'Answer A');
      expect(question.options[0].isCorrect, true); // First is correct
      expect(question.options[1].isCorrect, false);
    });

    test('AnswerOption model includes ID', () {
      final answer = AnswerOption(
        id: 'a_test456',
        text: 'Test answer',
        isCorrect: true,
        explanation: 'This is correct',
      );

      expect(answer.id, 'a_test456');
      expect(answer.text, 'Test answer');
      expect(answer.isCorrect, true);
      expect(answer.explanation, 'This is correct');

      final map = answer.toMap();
      expect(map['id'], 'a_test456');
      expect(map['text'], 'Test answer');
      expect(map['isCorrect'], true);
      expect(map['explanation'], 'This is correct');
    });
  });
}
