import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/player.dart';

class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Player> createPlayer({
    required String gameId,
    required String userId,
    required String username,
  }) async {
    print('[PlayerService] createPlayer - gameId: $gameId, userId: $userId, username: $username');
    final now = DateTime.now();
    final playerRef = _firestore.collection('games').doc(gameId).collection('players').doc();
    
    final player = Player(
      id: playerRef.id,
      userId: userId,
      username: username,
      createdAt: now,
      updatedAt: now,
    );

    await playerRef.set(player.toJson());
    print('[PlayerService] createPlayer - SUCCESS - playerId: ${player.id}');
    return player;
  }

  Future<void> updateQuestionnaireStatus(String gameId, String playerId, bool completed) async {
    print('[PlayerService] updateQuestionnaireStatus - gameId: $gameId, playerId: $playerId, completed: $completed');
    await _firestore.collection('games').doc(gameId).collection('players').doc(playerId).update({
      'has_completed_questionnaire': completed,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[PlayerService] updateQuestionnaireStatus - SUCCESS');
  }

  Future<void> updateScore(String gameId, String playerId, int points, {int? round}) async {
    print('[PlayerService] updateScore - gameId: $gameId, playerId: $playerId, points: $points, round: $round');
    final updates = {
      'score': FieldValue.increment(points),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
    
    if (round != null) {
      updates['round_scores.$round'] = FieldValue.increment(points);
    }
    
    await _firestore.collection('games').doc(gameId).collection('players').doc(playerId).update(updates);
    print('[PlayerService] updateScore - SUCCESS');
  }

  Stream<List<Player>> watchPlayers(String gameId) => _firestore
      .collection('games')
      .doc(gameId)
      .collection('players')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Player.fromJson(doc.data(), doc.id))
          .toList());

  Future<Player?> getPlayerByUserId(String gameId, String userId) async {
    final querySnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('players')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    
    final doc = querySnapshot.docs.first;
    return Player.fromJson(doc.data(), doc.id);
  }

  Future<void> deletePlayer(String gameId, String playerId) async {
    print('[PlayerService] deletePlayer - gameId: $gameId, playerId: $playerId');
    await _firestore.collection('games').doc(gameId).collection('players').doc(playerId).delete();
    print('[PlayerService] deletePlayer - SUCCESS');
  }
}
