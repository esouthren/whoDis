import 'package:cloud_firestore/cloud_firestore.dart';

class Guess {
  final String id;
  final int round;
  final String guesserId;
  final String? targetPlayerId;
  final int questionIndex;
  final int guessNumber;
  final DateTime createdAt;

  Guess({
    required this.id,
    required this.round,
    required this.guesserId,
    this.targetPlayerId,
    required this.questionIndex,
    required this.guessNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'round': round,
    'guesser_id': guesserId,
    'target_player_id': targetPlayerId,
    'question_index': questionIndex,
    'guess_number': guessNumber,
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory Guess.fromJson(Map<String, dynamic> json, String id) => Guess(
    id: id,
    round: json['round'] as int,
    guesserId: json['guesser_id'] as String,
    targetPlayerId: json['target_player_id'] as String?,
    questionIndex: json['question_index'] as int,
    guessNumber: json['guess_number'] as int,
    createdAt: (json['created_at'] as Timestamp).toDate(),
  );

  Guess copyWith({
    String? id,
    int? round,
    String? guesserId,
    String? targetPlayerId,
    int? questionIndex,
    int? guessNumber,
    DateTime? createdAt,
  }) => Guess(
    id: id ?? this.id,
    round: round ?? this.round,
    guesserId: guesserId ?? this.guesserId,
    targetPlayerId: targetPlayerId ?? this.targetPlayerId,
    questionIndex: questionIndex ?? this.questionIndex,
    guessNumber: guessNumber ?? this.guessNumber,
    createdAt: createdAt ?? this.createdAt,
  );
}
