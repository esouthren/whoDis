import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/question.dart';

class QuestionGenerationService {
  /// Generates questions for each player by calling the callable once per player in parallel.
  /// Each call must return exactly 6 questions (2 hard, 3 medium, 1 easy) for that player.
  /// Returns a map of playerId -> List<Question>. Throws if any player generation fails.
  static Future<Map<String, List<Question>>> generateQuestionsForAllPlayers({
    required List<String> playerIds,
  }) async {
    debugPrint('Calling generatePlayerQuestions per-player for ${playerIds.length} players');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in. Please sign in to generate questions.');
    }
    await user.getIdToken(true);

    final callable = FirebaseFunctions.instance.httpsCallable('generatePlayerQuestions');

    // Launch all requests in parallel; wait for all to finish and propagate any errors
    final futures = playerIds.map((playerId) async {
      final result = await callable.call().timeout(const Duration(seconds: 60));
      final decoded = result.data;
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response type for $playerId');
      }
      if (decoded['success'] != true) {
        throw Exception('Function returned unsuccessful result for $playerId');
      }
      final questionsJson = (decoded['questions'] as List<dynamic>? ?? const []);
      final questions = questionsJson.map((q) {
        final m = (q as Map<String, dynamic>);
        final text = m['text']?.toString() ?? '';
        final difficultyStr = m['difficulty']?.toString() ?? 'medium';
        final difficulty = _parseDifficulty(difficultyStr);
        return Question(text, difficulty);
      }).toList();

      if (questions.length != 6) {
        throw Exception('Player $playerId received ${questions.length} questions; expected 6');
      }

      return MapEntry(playerId, questions);
    }).toList();

    try {
      final entries = await Future.wait(futures, eagerError: false);
      final map = Map<String, List<Question>>.fromEntries(entries);
      debugPrint('Finished generating questions for ${map.length} players');
      return map;
    } catch (e) {
      debugPrint('Error generating questions via callable (batch-level): $e');
      rethrow; // Propagate failure to caller
    }
  }

  /// Generates questions for a single player by calling the callable once.
  /// Returns exactly 6 questions or throws on error.
  static Future<List<Question>> generateQuestionsForPlayer({
    required String playerId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please sign in to generate questions.');
      }
      await user.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable('generatePlayerQuestions');
      final result = await callable.call().timeout(const Duration(seconds: 60));
      final decoded = result.data;
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response type for $playerId');
      }
      if (decoded['success'] != true) {
        throw Exception('Function returned unsuccessful result for $playerId');
      }
      final questionsJson = (decoded['questions'] as List<dynamic>? ?? const []);
      final questions = questionsJson.map((q) {
        final m = (q as Map<String, dynamic>);
        final text = m['text']?.toString() ?? '';
        final difficultyStr = m['difficulty']?.toString() ?? 'medium';
        final difficulty = _parseDifficulty(difficultyStr);
        return Question(text, difficulty);
      }).toList();

      if (questions.length != 6) {
        throw Exception('Player $playerId received ${questions.length} questions; expected 6');
      }

      return questions;
    } catch (e) {
      debugPrint('Error generating questions for $playerId: $e');
      rethrow; // Propagate failure to caller
    }
  }

  /// Parse difficulty string to enum
  static QuestionDifficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'hard':
        return QuestionDifficulty.hard;
      case 'medium':
        return QuestionDifficulty.medium;
      case 'easy':
        return QuestionDifficulty.easy;
      default:
        debugPrint('Unknown difficulty: $difficulty, defaulting to medium');
        return QuestionDifficulty.medium;
    }
  }
}
