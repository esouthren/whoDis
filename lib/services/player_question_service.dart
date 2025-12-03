import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/player_question.dart';

class PlayerQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePlayerQuestions({
    required String gameId,
    required String playerId,
    required List<PlayerQuestion> questions,
  }) async {
    print('[PlayerQuestionService] savePlayerQuestions - gameId: $gameId, playerId: $playerId, questions count: ${questions.length}');
    
    try {
      final batch = _firestore.batch();
      
      for (final question in questions) {
        final questionRef = _firestore
            .collection('games')
            .doc(gameId)
            .collection('players')
            .doc(playerId)
            .collection('player_questions')
            .doc();
        
        batch.set(questionRef, question.copyWith(id: questionRef.id).toJson());
      }
      
      await batch.commit();
      print('[PlayerQuestionService] savePlayerQuestions - SUCCESS');
    } catch (e, stackTrace) {
      print('[PlayerQuestionService] savePlayerQuestions - ERROR: $e');
      print('[PlayerQuestionService] savePlayerQuestions - STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<List<PlayerQuestion>> getPlayerQuestions(String gameId, String playerId) async {
    print('[PlayerQuestionService] getPlayerQuestions - gameId: $gameId, playerId: $playerId');
    
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('players')
        .doc(playerId)
        .collection('player_questions')
        .orderBy('order')
        .get();

    final questions = querySnapshot.docs
        .map((doc) => PlayerQuestion.fromJson(doc.data(), doc.id))
        .toList();
    
    print('[PlayerQuestionService] getPlayerQuestions - SUCCESS - found ${questions.length} questions');
    return questions;
  }

  Stream<List<PlayerQuestion>> watchPlayerQuestions(String gameId, String playerId) => _firestore
      .collection('games')
      .doc(gameId)
      .collection('players')
      .doc(playerId)
      .collection('player_questions')
      .orderBy('order')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PlayerQuestion.fromJson(doc.data(), doc.id))
          .toList());
}
