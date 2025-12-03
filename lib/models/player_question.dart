import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerQuestion {
  final String id;
  final String questionText;
  final String answer;
  final String difficulty;
  final int order;
  final DateTime createdAt;

  PlayerQuestion({
    required this.id,
    required this.questionText,
    required this.answer,
    required this.difficulty,
    required this.order,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question_text': questionText,
    'answer': answer,
    'difficulty': difficulty,
    'order': order,
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory PlayerQuestion.fromJson(Map<String, dynamic> json, String id) => PlayerQuestion(
    id: id,
    questionText: json['question_text'] as String,
    answer: json['answer'] as String,
    difficulty: json['difficulty'] as String,
    order: json['order'] as int,
    createdAt: (json['created_at'] as Timestamp).toDate(),
  );

  PlayerQuestion copyWith({
    String? id,
    String? questionText,
    String? answer,
    String? difficulty,
    int? order,
    DateTime? createdAt,
  }) => PlayerQuestion(
    id: id ?? this.id,
    questionText: questionText ?? this.questionText,
    answer: answer ?? this.answer,
    difficulty: difficulty ?? this.difficulty,
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
  );
}
