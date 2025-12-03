import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/round_questions.dart';
import 'package:whodis/models/player_question.dart';

class RoundQuestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RoundQuestions> createRoundQuestions({
    required String gameId,
    required int round,
    required List<PlayerQuestion> playerQuestions,
  }) async {
    print('[RoundQuestionsService] createRoundQuestions - gameId: $gameId, round: $round');
    final now = DateTime.now();
    final roundQuestionsRef = _firestore
        .collection('games')
        .doc(gameId)
        .collection('round_questions')
        .doc();
    
    // Sort questions by difficulty (hard, medium, easy) to ensure proper order
    final sortedQuestions = List<PlayerQuestion>.from(playerQuestions)
      ..sort((a, b) {
        final difficultyOrder = {'hard': 0, 'medium': 1, 'easy': 2};
        final aOrder = difficultyOrder[a.difficulty] ?? 3;
        final bOrder = difficultyOrder[b.difficulty] ?? 3;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.order.compareTo(b.order);
      });
    
    final questionTexts = sortedQuestions.map((pq) => pq.questionText).toList();
    final answerTexts = sortedQuestions.map((pq) => pq.answer).toList();
    
    final roundQuestions = RoundQuestions(
      id: roundQuestionsRef.id,
      gameId: gameId,
      round: round,
      questions: questionTexts,
      answers: answerTexts,
      createdAt: now,
    );

    await roundQuestionsRef.set(roundQuestions.toJson());
    print('[RoundQuestionsService] createRoundQuestions - SUCCESS - roundQuestionsId: ${roundQuestions.id}');
    return roundQuestions;
  }

  Future<RoundQuestions?> getRoundQuestions(String gameId, int round) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('round_questions')
        .where('round', isEqualTo: round)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    
    final doc = querySnapshot.docs.first;
    return RoundQuestions.fromJson(doc.data(), doc.id);
  }

  Stream<RoundQuestions?> watchRoundQuestions(String gameId, int round) => _firestore
      .collection('games')
      .doc(gameId)
      .collection('round_questions')
      .where('round', isEqualTo: round)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isEmpty 
          ? null 
          : RoundQuestions.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id));
}
