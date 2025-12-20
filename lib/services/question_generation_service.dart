import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/question.dart';

class QuestionGenerationService {
  /// Generates questions for each player by calling the callable once per player in parallel.
  /// Each call returns 6 questions (2 hard, 3 medium, 1 easy) for that player.
  /// Returns a map of playerId -> List<Question>.
  static Future<Map<String, List<Question>>> generateQuestionsForAllPlayers({
    required List<String> playerIds,
  }) async {
    try {
      debugPrint('Calling generatePlayerQuestions per-player for ${playerIds.length} players');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please sign in to generate questions.');
      }
      await user.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable('generatePlayerQuestions');

      // Launch all requests in parallel, with per-player error handling and fallback
      final futures = playerIds.map((playerId) async {
        try {
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
            debugPrint('Player $playerId received ${questions.length} questions, topping up from fallback');
            // Top-up to 6 from local fallback if needed
            final fallback = localFallbackQuestionsOnePlayer();
            final filled = [...questions, ...fallback].take(6).toList();
            return MapEntry(playerId, filled);
          }

          return MapEntry(playerId, questions);
        } catch (e) {
          debugPrint('Error generating questions for $playerId: $e');
          return MapEntry(playerId, localFallbackQuestionsOnePlayer());
        }
      });

      final entries = await Future.wait(futures);
      final map = Map<String, List<Question>>.fromEntries(entries);
      debugPrint('Finished generating questions for ${map.length} players');
      return map;
    } catch (e) {
      debugPrint('Error generating questions via callable (batch-level): $e');
      // Batch-level failure fallback
      final result = <String, List<Question>>{};
      for (final playerId in playerIds) {
        result[playerId] = localFallbackQuestionsOnePlayer();
      }
      return result;
    }
  }

  /// Generates questions for a single player by calling the callable once.
  /// Always returns 6 questions, topping up from local fallback if needed.
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
        debugPrint('Player $playerId received ${questions.length} questions, topping up from fallback');
        final fallback = localFallbackQuestionsOnePlayer();
        return [...questions, ...fallback].take(6).toList();
      }

      return questions;
    } catch (e) {
      debugPrint('Error generating questions for $playerId: $e');
      return localFallbackQuestionsOnePlayer();
    }
  }

  /// Local fallback: returns 6 questions (2 hard, 3 medium, 1 easy)
  /// This no longer depends on a giant allQuestions list.
  static List<Question> localFallbackQuestionsOnePlayer() {
    final hard = <Question>[
      const Question('What was the first thing you ate today?', QuestionDifficulty.hard),
      const Question('Do you prefer mornings or nights?', QuestionDifficulty.hard),
      const Question('What app do you open first most mornings?', QuestionDifficulty.hard),
      const Question('Do you prefer cats or dogs?', QuestionDifficulty.hard),
    ]..shuffle();

    final medium = <Question>[
      const Question('What is your favorite hobby?', QuestionDifficulty.medium),
      const Question('What type of music do you listen to?', QuestionDifficulty.medium),
      const Question('What is your favorite food?', QuestionDifficulty.medium),
      const Question('What’s your favorite movie genre?', QuestionDifficulty.medium),
      const Question('What did you do last weekend?', QuestionDifficulty.medium),
    ]..shuffle();

    final easy = <Question>[
      const Question('What country do you live in?', QuestionDifficulty.easy),
      const Question('What is your job or field of study?', QuestionDifficulty.easy),
      const Question('What’s your current city?', QuestionDifficulty.easy),
    ]..shuffle();

    final list = <Question>[];
    list.addAll(hard.take(2));
    list.addAll(medium.take(3));
    if (easy.isNotEmpty) list.add(easy.first);
    return list;
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
