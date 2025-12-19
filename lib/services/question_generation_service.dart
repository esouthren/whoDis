import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/constants/questions.dart';

class QuestionGenerationService {
  /// Generates all questions for all players in one batch using callable function
  /// Each player gets: 2 hard, 3 medium, 1 easy (6 questions per player)
  /// Returns a map of playerId -> List of 6 questions
  static Future<Map<String, List<Question>>> generateQuestionsForAllPlayers({
    required List<String> playerIds,
  }) async {
    try {
      debugPrint('Calling generatePlayerQuestions (callable) for ${playerIds.length} players');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please sign in to generate questions.');
      }
      // Ensure a fresh token is available (SDK attaches it automatically)
      await user.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable('generatePlayerQuestions');
      final result = await callable.call({'numberOfPlayers': playerIds.length}).timeout(const Duration(seconds: 30));

      final decoded = result.data;
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response type');
      }

      if (decoded['success'] != true) {
        throw Exception('Function returned unsuccessful result');
      }

      final questionsJson = (decoded['questions'] as List<dynamic>? ?? const []);

      // Convert JSON to Question objects
      final allGenerated = questionsJson.map((q) {
        final text = (q as Map<String, dynamic>)['text']?.toString() ?? '';
        final difficultyStr = (q)['difficulty']?.toString() ?? 'medium';
        final difficulty = _parseDifficulty(difficultyStr);
        return Question(text, difficulty);
      }).toList();

      debugPrint('Endpoint produced ${allGenerated.length} questions');

      // Distribute questions to players: each gets 2 hard, 3 medium, 1 easy
      final distributed = _distributeQuestionsToPlayers(allGenerated, playerIds);

      // Ensure every player gets 6 questions; if not, top-up from local fallback
      for (final id in playerIds) {
        final list = distributed[id] ?? <Question>[];
        if (list.length < 6) {
          final needed = 6 - list.length;
          final fallback = _fallbackQuestionsOnePlayer();
          // Add questions up to the needed count
          final toAdd = <Question>[];
          for (final q in fallback) {
            if (toAdd.length >= needed) break;
            toAdd.add(q);
          }
          distributed[id] = [...list, ...toAdd].take(6).toList();
          debugPrint('Topped up player $id with $needed fallback questions');
        }
      }

      return distributed;
    } catch (e) {
      debugPrint('Error generating questions via callable: $e');

      // Fallback to local questions if the endpoint fails
      debugPrint('Falling back to local questions for all players');
      final result = <String, List<Question>>{};
      for (final playerId in playerIds) {
        result[playerId] = _fallbackQuestionsOnePlayer();
      }
      return result;
    }
  }

  /// Distributes questions to players ensuring each gets 2 hard, 3 medium, 1 easy
  static Map<String, List<Question>> _distributeQuestionsToPlayers(
    List<Question> allQuestions,
    List<String> playerIds,
  ) {
    // Separate questions by difficulty
    final hardQuestions = allQuestions.where((q) => q.difficulty == QuestionDifficulty.hard).toList();
    final mediumQuestions = allQuestions.where((q) => q.difficulty == QuestionDifficulty.medium).toList();
    final easyQuestions = allQuestions.where((q) => q.difficulty == QuestionDifficulty.easy).toList();

    debugPrint('Distributing: ${hardQuestions.length} hard, ${mediumQuestions.length} medium, ${easyQuestions.length} easy');

    final result = <String, List<Question>>{};

    int hardIndex = 0;
    int mediumIndex = 0;
    int easyIndex = 0;

    for (final playerId in playerIds) {
      final playerQuestions = <Question>[];

      // Assign 2 hard questions
      for (int i = 0; i < 2 && hardIndex < hardQuestions.length; i++) {
        playerQuestions.add(hardQuestions[hardIndex++]);
      }

      // Assign 3 medium questions
      for (int i = 0; i < 3 && mediumIndex < mediumQuestions.length; i++) {
        playerQuestions.add(mediumQuestions[mediumIndex++]);
      }

      // Assign 1 easy question
      if (easyIndex < easyQuestions.length) {
        playerQuestions.add(easyQuestions[easyIndex++]);
      }

      result[playerId] = playerQuestions;
      debugPrint('Player $playerId assigned ${playerQuestions.length} questions');
    }

    return result;
  }

  /// Local fallback: returns 6 questions in distribution 2 hard, 3 medium, 1 easy
  static List<Question> _fallbackQuestionsOnePlayer() {
    final hard = allQuestions.where((q) => q.difficulty == QuestionDifficulty.hard).toList()..shuffle();
    final medium = allQuestions.where((q) => q.difficulty == QuestionDifficulty.medium).toList()..shuffle();
    final easy = allQuestions.where((q) => q.difficulty == QuestionDifficulty.easy).toList()..shuffle();
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
