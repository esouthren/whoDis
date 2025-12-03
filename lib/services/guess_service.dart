import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/guess.dart';

class GuessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGuess({
    required String gameId,
    required int round,
    required String guesserId,
    required String? targetPlayerId,
    required int questionIndex,
    required int guessNumber,
  }) async {
    print('[GuessService] saveGuess - gameId: $gameId, round: $round, guesserId: $guesserId, targetPlayerId: $targetPlayerId, questionIndex: $questionIndex, guessNumber: $guessNumber');
    final guessRef = _firestore.collection('games').doc(gameId).collection('guesses').doc();
    
    final guess = Guess(
      id: guessRef.id,
      round: round,
      guesserId: guesserId,
      targetPlayerId: targetPlayerId,
      questionIndex: questionIndex,
      guessNumber: guessNumber,
      createdAt: DateTime.now(),
    );

    await guessRef.set(guess.toJson());
    print('[GuessService] saveGuess - SUCCESS - guessId: ${guess.id}');
  }

  Stream<List<Guess>> watchGuesses(String gameId, int round) => _firestore
      .collection('games')
      .doc(gameId)
      .collection('guesses')
      .where('round', isEqualTo: round)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Guess.fromJson(doc.data(), doc.id))
          .toList());

  Future<List<Guess>> getAllGuesses(String gameId) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('guesses')
        .get();

    return querySnapshot.docs
        .map((doc) => Guess.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<Guess?> getPlayerGuessForRound(String gameId, int round, String guesserId) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('guesses')
        .where('round', isEqualTo: round)
        .where('guesser_id', isEqualTo: guesserId)
        .where('guess_number', isEqualTo: 1)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    
    final doc = querySnapshot.docs.first;
    return Guess.fromJson(doc.data(), doc.id);
  }

  Future<int> getGuessCount(String gameId, int round, String guesserId) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('guesses')
        .where('round', isEqualTo: round)
        .where('guesser_id', isEqualTo: guesserId)
        .get();

    return querySnapshot.docs.length;
  }
}
