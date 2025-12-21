import 'package:cloud_firestore/cloud_firestore.dart';

enum GameState {
  starting,
  lobby,
  questionnaire,
  game,
  finished,
}

class Game {
  final String id;
  final String password;
  final String creatorId;
  final GameState state;
  final List<String> playerIds;
  final List<String> roundOrder;
  final int? currentRound;
  final int? currentQuestionIndex;
  final DateTime? questionStartTime;
  final int? currentResultsPage;
  final List<int> revealedRounds;
  final int timerDuration;
  final int? numberOfRounds;
  final bool questionsGenerated;
  final bool preparingQuestions;
  final bool betweenRounds;
  final bool endingGame;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    required this.id,
    required this.password,
    required this.creatorId,
    required this.state,
    required this.playerIds,
    this.roundOrder = const [],
    this.currentRound,
    this.currentQuestionIndex,
    this.questionStartTime,
    this.currentResultsPage,
    this.revealedRounds = const [],
    this.timerDuration = 12,
    this.numberOfRounds,
    this.questionsGenerated = false,
    this.preparingQuestions = false,
    this.betweenRounds = false,
    this.endingGame = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'password': password,
    'creator_id': creatorId,
    'state': state.name,
    'player_ids': playerIds,
    'round_order': roundOrder,
    'current_round': currentRound,
    'current_question_index': currentQuestionIndex,
    'question_start_time': questionStartTime != null ? Timestamp.fromDate(questionStartTime!) : null,
    'current_results_page': currentResultsPage,
    'revealed_rounds': revealedRounds,
    'timer_duration': timerDuration,
    'number_of_rounds': numberOfRounds,
    'questions_generated': questionsGenerated,
    'preparing_questions': preparingQuestions,
    'between_rounds': betweenRounds,
    'ending_game': endingGame,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory Game.fromJson(Map<String, dynamic> json, String id) => Game(
    id: id,
    password: json['password'] as String,
    creatorId: json['creator_id'] as String,
    state: GameState.values.firstWhere((e) => e.name == json['state']),
    playerIds: List<String>.from(json['player_ids'] ?? []),
    roundOrder: List<String>.from(json['round_order'] ?? []),
    currentRound: json['current_round'] as int?,
    currentQuestionIndex: json['current_question_index'] as int?,
    questionStartTime: json['question_start_time'] != null ? (json['question_start_time'] as Timestamp).toDate() : null,
    currentResultsPage: json['current_results_page'] as int?,
    revealedRounds: List<int>.from(json['revealed_rounds'] ?? []),
    timerDuration: json['timer_duration'] as int? ?? 12,
    numberOfRounds: json['number_of_rounds'] as int?,
    questionsGenerated: json['questions_generated'] as bool? ?? false,
    preparingQuestions: json['preparing_questions'] as bool? ?? false,
    betweenRounds: json['between_rounds'] as bool? ?? false,
    endingGame: json['ending_game'] as bool? ?? false,
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );

  Game copyWith({
    String? id,
    String? password,
    String? creatorId,
    GameState? state,
    List<String>? playerIds,
    List<String>? roundOrder,
    int? currentRound,
    int? currentQuestionIndex,
    DateTime? questionStartTime,
    int? currentResultsPage,
    List<int>? revealedRounds,
    int? timerDuration,
    int? numberOfRounds,
    bool? questionsGenerated,
    bool? preparingQuestions,
    bool? betweenRounds,
    bool? endingGame,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Game(
    id: id ?? this.id,
    password: password ?? this.password,
    creatorId: creatorId ?? this.creatorId,
    state: state ?? this.state,
    playerIds: playerIds ?? this.playerIds,
    roundOrder: roundOrder ?? this.roundOrder,
    currentRound: currentRound ?? this.currentRound,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    questionStartTime: questionStartTime ?? this.questionStartTime,
    currentResultsPage: currentResultsPage ?? this.currentResultsPage,
    revealedRounds: revealedRounds ?? this.revealedRounds,
    timerDuration: timerDuration ?? this.timerDuration,
    numberOfRounds: numberOfRounds ?? this.numberOfRounds,
    questionsGenerated: questionsGenerated ?? this.questionsGenerated,
    preparingQuestions: preparingQuestions ?? this.preparingQuestions,
    betweenRounds: betweenRounds ?? this.betweenRounds,
    endingGame: endingGame ?? this.endingGame,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
