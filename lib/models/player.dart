import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String userId;
  final String username;
  final bool hasCompletedQuestionnaire;
  final int score;
  final Map<int, int> roundScores;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final String? image;

  Player({
    required this.id,
    required this.userId,
    required this.username,
    this.hasCompletedQuestionnaire = false,
    this.score = 0,
    this.roundScores = const {},
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'username': username,
        'has_completed_questionnaire': hasCompletedQuestionnaire,
        'score': score,
        'round_scores': roundScores,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
        'email': email,
        'image': image,
      };

  factory Player.fromJson(Map<String, dynamic> json, String id) => Player(
        id: id,
        userId: json['user_id'] as String,
        username: json['username'] as String,
        hasCompletedQuestionnaire:
            json['has_completed_questionnaire'] as bool? ?? false,
        score: json['score'] as int? ?? 0,
        roundScores: json['round_scores'] != null
            ? Map<int, int>.from((json['round_scores'] as Map).map(
                (key, value) => MapEntry(int.parse(key.toString()), value as int)))
            : {},
        createdAt: (json['created_at'] as Timestamp).toDate(),
        updatedAt: (json['updated_at'] as Timestamp).toDate(),
        email: (json['email'] as String?)?.trim().isEmpty == true
            ? null
            : json['email'] as String?,
        image: (json['image'] as String?)?.trim().isEmpty == true
            ? null
            : json['image'] as String?,
      );

  Player copyWith({
    String? id,
    String? userId,
    String? username,
    bool? hasCompletedQuestionnaire,
    int? score,
    Map<int, int>? roundScores,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? image,
  }) =>
      Player(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        username: username ?? this.username,
        hasCompletedQuestionnaire:
            hasCompletedQuestionnaire ?? this.hasCompletedQuestionnaire,
        score: score ?? this.score,
        roundScores: roundScores ?? this.roundScores,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        email: email ?? this.email,
        image: image ?? this.image,
      );
}
