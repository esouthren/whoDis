import 'package:cloud_firestore/cloud_firestore.dart';

class RoundQuestions {
  final String id;
  final String gameId;
  final int round;
  final List<String> questions;
  final List<String> answers;
  final DateTime createdAt;

  RoundQuestions({
    required this.id,
    required this.gameId,
    required this.round,
    required this.questions,
    required this.answers,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'game_id': gameId,
    'round': round,
    'questions': questions,
    'answers': answers,
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory RoundQuestions.fromJson(Map<String, dynamic> json, String id) => RoundQuestions(
    id: id,
    gameId: json['game_id'] as String,
    round: json['round'] as int,
    questions: List<String>.from(json['questions'] ?? []),
    answers: List<String>.from(json['answers'] ?? []),
    createdAt: (json['created_at'] as Timestamp).toDate(),
  );

  RoundQuestions copyWith({
    String? id,
    String? gameId,
    int? round,
    List<String>? questions,
    List<String>? answers,
    DateTime? createdAt,
  }) => RoundQuestions(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    round: round ?? this.round,
    questions: questions ?? this.questions,
    answers: answers ?? this.answers,
    createdAt: createdAt ?? this.createdAt,
  );
}
