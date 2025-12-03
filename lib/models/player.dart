import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String userId;
  final String username;
  final bool hasCompletedQuestionnaire;
  final int score;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    required this.id,
    required this.userId,
    required this.username,
    this.hasCompletedQuestionnaire = false,
    this.score = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'has_completed_questionnaire': hasCompletedQuestionnaire,
    'score': score,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory Player.fromJson(Map<String, dynamic> json, String id) => Player(
    id: id,
    userId: json['user_id'] as String,
    username: json['username'] as String,
    hasCompletedQuestionnaire: json['has_completed_questionnaire'] as bool? ?? false,
    score: json['score'] as int? ?? 0,
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );

  Player copyWith({
    String? id,
    String? userId,
    String? username,
    bool? hasCompletedQuestionnaire,
    int? score,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Player(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    hasCompletedQuestionnaire: hasCompletedQuestionnaire ?? this.hasCompletedQuestionnaire,
    score: score ?? this.score,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
