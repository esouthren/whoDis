import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/game.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generatePassword() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<Game> createGame(String creatorId, {int timerDuration = 12, int? numberOfRounds}) async {
    print('[GameService] createGame - creatorId: $creatorId, timerDuration: $timerDuration, numberOfRounds: $numberOfRounds');
    final password = _generatePassword();
    final now = DateTime.now();
    
    final gameRef = _firestore.collection('games').doc();
    final game = Game(
      id: gameRef.id,
      password: password,
      creatorId: creatorId,
      state: GameState.starting,
      playerIds: [creatorId],
      timerDuration: timerDuration,
      numberOfRounds: numberOfRounds,
      createdAt: now,
      updatedAt: now,
    );

    await gameRef.set(game.toJson());
    print('[GameService] createGame - SUCCESS - gameId: ${game.id}, password: $password');
    return game;
  }

  Future<Game?> getGameByPassword(String password) async {
    print('[GameService] getGameByPassword - password: $password');
    final querySnapshot = await _firestore
        .collection('games')
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('[GameService] getGameByPassword - NOT FOUND');
      return null;
    }
    
    final doc = querySnapshot.docs.first;
    print('[GameService] getGameByPassword - FOUND - gameId: ${doc.id}');
    return Game.fromJson(doc.data(), doc.id);
  }

  Future<void> joinGame(String gameId, String userId) async {
    print('[GameService] joinGame - gameId: $gameId, userId: $userId');
    final gameRef = _firestore.collection('games').doc(gameId);
    await gameRef.update({
      'player_ids': FieldValue.arrayUnion([userId]),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] joinGame - SUCCESS');
  }

  Future<void> leaveGame(String gameId, String userId) async {
    print('[GameService] leaveGame - gameId: $gameId, userId: $userId');
    final gameRef = _firestore.collection('games').doc(gameId);
    await gameRef.update({
      'player_ids': FieldValue.arrayRemove([userId]),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] leaveGame - SUCCESS');
  }

  Future<void> updateGameState(String gameId, GameState state) async {
    print('[GameService] updateGameState - gameId: $gameId, state: ${state.name}');
    await _firestore.collection('games').doc(gameId).update({
      'state': state.name,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] updateGameState - SUCCESS');
  }

  Future<void> updateCurrentRound(String gameId, int round) async {
    print('[GameService] updateCurrentRound - gameId: $gameId, round: $round');
    await _firestore.collection('games').doc(gameId).update({
      'current_round': round,
      'current_question_index': 0,
      'question_start_time': FieldValue.serverTimestamp(),
      'between_rounds': false,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] updateCurrentRound - SUCCESS');
  }

  Future<void> setBetweenRounds(String gameId, bool value) async {
    print('[GameService] setBetweenRounds - gameId: $gameId, value: $value');
    await _firestore.collection('games').doc(gameId).update({
      'between_rounds': value,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] setBetweenRounds - SUCCESS');
  }

  Future<void> setEndingGame(String gameId, bool value) async {
    print('[GameService] setEndingGame - gameId: $gameId, value: $value');
    await _firestore.collection('games').doc(gameId).update({
      'ending_game': value,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] setEndingGame - SUCCESS');
  }

  Future<void> advanceQuestion(String gameId, int questionIndex) async {
    print('[GameService] advanceQuestion - gameId: $gameId, questionIndex: $questionIndex');
    await _firestore.collection('games').doc(gameId).update({
      'current_question_index': questionIndex,
      'question_start_time': FieldValue.serverTimestamp(),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] advanceQuestion - SUCCESS');
  }

  Future<void> startRoundTimer(String gameId) async {
    print('[GameService] startRoundTimer - gameId: $gameId');
    await _firestore.collection('games').doc(gameId).update({
      'current_question_index': 0,
      'question_start_time': FieldValue.serverTimestamp(),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] startRoundTimer - SUCCESS');
  }

  Future<void> updateCurrentResultsPage(String gameId, int page) async {
    print('[GameService] updateCurrentResultsPage - gameId: $gameId, page: $page');
    await _firestore.collection('games').doc(gameId).update({
      'current_results_page': page,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] updateCurrentResultsPage - SUCCESS');
  }

  Future<void> revealRound(String gameId, int roundIndex) async {
    print('[GameService] revealRound - gameId: $gameId, roundIndex: $roundIndex');
    await _firestore.collection('games').doc(gameId).update({
      'revealed_rounds': FieldValue.arrayUnion([roundIndex]),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] revealRound - SUCCESS');
  }

  Future<void> setRoundOrder(String gameId, List<String> roundOrder) async {
    print('[GameService] setRoundOrder - gameId: $gameId, roundOrder: $roundOrder');
    await _firestore.collection('games').doc(gameId).update({
      'round_order': roundOrder,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[GameService] setRoundOrder - SUCCESS');
  }

  Future<Game?> getGame(String gameId) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    return doc.exists ? Game.fromJson(doc.data()!, doc.id) : null;
  }

  Stream<Game?> watchGame(String gameId) => _firestore
      .collection('games')
      .doc(gameId)
      .snapshots()
      .map((doc) => doc.exists ? Game.fromJson(doc.data()!, doc.id) : null);

  Future<void> deleteGame(String gameId) async {
    print('[GameService] deleteGame - gameId: $gameId');
    await _firestore.collection('games').doc(gameId).delete();
    print('[GameService] deleteGame - SUCCESS');
  }
}
