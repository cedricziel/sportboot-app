import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for generating unique, deterministic IDs for questions and answers
class IdGenerator {
  /// Generate a unique ID for a question based on its content
  /// Format: q_{hash}
  static String generateQuestionId({
    required int number,
    required String text,
    required String category,
  }) {
    // Combine question properties to create unique identifier
    final content = '$category-$number-${_normalizeText(text)}';
    final hash = _generateHash(content);
    return 'q_$hash';
  }

  /// Generate a unique ID for an answer based on its content
  /// Format: a_{hash}
  static String generateAnswerId({
    required String questionId,
    required int index,
    required String text,
  }) {
    // Combine answer properties with question ID to ensure uniqueness
    final content = '$questionId-$index-${_normalizeText(text)}';
    final hash = _generateHash(content);
    return 'a_$hash';
  }

  /// Generate SHA-256 hash and return first 12 characters
  static String _generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    // Return first 12 characters of hex digest for readability
    return digest.toString().substring(0, 12);
  }

  /// Normalize text to ensure consistent ID generation
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .trim();
  }
}