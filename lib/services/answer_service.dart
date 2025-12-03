import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/answer.dart';

class AnswerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveAnswers({
    required String gameId,
    required String playerId,
    required Map<int, String> answers,
  }) async {
    print('[AnswerService] saveAnswers - gameId: $gameId, playerId: $playerId, answers count: ${answers.length}');
    
    try {
      // First verify the game document exists
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        print('[AnswerService] saveAnswers - ERROR: Game document does not exist: $gameId');
        throw Exception('Game not found: $gameId');
      }
      
      final now = DateTime.now();
      final answerRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('answers')
          .doc();
      
      final answer = Answer(
        id: answerRef.id,
        gameId: gameId,
        playerId: playerId,
        answers: answers,
        createdAt: now,
        updatedAt: now,
      );

      await answerRef.set(answer.toJson());
      print('[AnswerService] saveAnswers - SUCCESS - answerId: ${answer.id}');
    } catch (e, stackTrace) {
      print('[AnswerService] saveAnswers - ERROR: $e');
      print('[AnswerService] saveAnswers - STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<Answer?> getAnswersByPlayer(String gameId, String playerId) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('answers')
        .where('player_id', isEqualTo: playerId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    
    final doc = querySnapshot.docs.first;
    return Answer.fromJson(doc.data(), doc.id);
  }

  Stream<List<Answer>> watchAnswers(String gameId) => _firestore
      .collection('games')
      .doc(gameId)
      .collection('answers')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Answer.fromJson(doc.data(), doc.id))
          .toList());
}
