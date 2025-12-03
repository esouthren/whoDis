import 'package:cloud_firestore/cloud_firestore.dart';

class Answer {
  final String id;
  final String gameId;
  final String playerId;
  final Map<int, String> answers;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'game_id': gameId,
    'player_id': playerId,
    'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory Answer.fromJson(Map<String, dynamic> json, String id) => Answer(
    id: id,
    gameId: json['game_id'] as String,
    playerId: json['player_id'] as String,
    answers: (json['answers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v as String),
    ),
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );

  Answer copyWith({
    String? id,
    String? gameId,
    String? playerId,
    Map<int, String>? answers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Answer(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    playerId: playerId ?? this.playerId,
    answers: answers ?? this.answers,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
