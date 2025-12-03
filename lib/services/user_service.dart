import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(String userId, String username) async {
    print('[UserService] saveUser - userId: $userId, username: $username');
    final now = DateTime.now();
    final userDoc = _firestore.collection('users').doc(userId);
    
    final existingUser = await userDoc.get();
    
    if (existingUser.exists) {
      await userDoc.update({
        'username': username,
        'updated_at': Timestamp.fromDate(now),
      });
      print('[UserService] saveUser - SUCCESS (updated)');
    } else {
      final user = AppUser(
        id: userId,
        username: username,
        createdAt: now,
        updatedAt: now,
      );
      await userDoc.set(user.toJson());
      print('[UserService] saveUser - SUCCESS (created)');
    }
  }

  Future<void> setActiveGame(String userId, String? gameId) async {
    print('[UserService] setActiveGame - userId: $userId, gameId: $gameId');
    await _firestore.collection('users').doc(userId).update({
      'active_game': gameId,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
    print('[UserService] setActiveGame - SUCCESS');
  }

  Stream<AppUser?> watchUser(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromJson(doc.data()!, doc.id) : null);
}
