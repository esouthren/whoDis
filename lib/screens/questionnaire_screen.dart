import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/constants/questions.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/player_question_service.dart';
import 'package:whodis/models/player_question.dart';
import 'package:whodis/services/round_questions_service.dart';
import 'package:whodis/services/question_generation_service.dart';
import 'package:whodis/screens/game_screen.dart';
import 'package:whodis/screens/countdown_screen.dart';
import 'package:whodis/widgets/loading_overlay.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String gameId;

  const QuestionnaireScreen({super.key, required this.gameId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final Map<int, String> answers = {};
  final Map<int, TextEditingController> controllers = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasNavigatedToCountdown = false;
  List<Question> _selectedQuestions = [];
  bool _questionsInitialized = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      controllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isStartingGame = false;

  bool _currentQuestionAnswered() {
    final answer = answers[_currentPage];
    return answer != null && answer.trim().isNotEmpty;
  }

  void _goToNextQuestion() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _initializeQuestions(String playerId, Game game, List<Player> allPlayers) async {
    if (_questionsInitialized) return;

    final playerQuestionService = PlayerQuestionService();
    final existingQuestions = await playerQuestionService.getPlayerQuestions(widget.gameId, playerId);

    if (existingQuestions.isEmpty) {
      // Check if questions have been generated for the game yet
      if (!game.questionsGenerated) {
        debugPrint('Questions not yet generated for game. Generating for all ${allPlayers.length} players...');
        
        // Generate questions for ALL players at once
        final allPlayerIds = allPlayers.map((p) => p.id).toList();
        final questionsMap = await QuestionGenerationService.generateQuestionsForAllPlayers(
          playerIds: allPlayerIds,
        );
        
        // Store questions for all players in Firestore
        for (final player in allPlayers) {
          final questions = questionsMap[player.id];
          if (questions != null) {
            // Convert Question objects to PlayerQuestion objects
            final playerQuestions = questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return PlayerQuestion(
                id: '',
                questionText: question.text,
                answer: '',
                difficulty: question.difficulty.name,
                order: index,
                createdAt: DateTime.now(),
              );
            }).toList();
            
            await playerQuestionService.savePlayerQuestions(
              gameId: widget.gameId,
              playerId: player.id,
              questions: playerQuestions,
            );
          }
        }
        
        // Mark game as having questions generated
        await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update({
            'questions_generated': true,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });
        
        debugPrint('Successfully generated and stored questions for all players');
        
        // Use the questions for current player
        _selectedQuestions = questionsMap[playerId] ?? [];
      } else {
        // Questions were generated but not found for this player (shouldn't happen)
        debugPrint('Questions should exist but not found for player $playerId');
        _selectedQuestions = getRandomizedQuestionsForRound();
      }
    } else {
      // Reconstruct questions from existing player_questions
      _selectedQuestions = existingQuestions.map((pq) {
        final difficulty = pq.difficulty == 'hard' 
            ? QuestionDifficulty.hard 
            : pq.difficulty == 'medium' 
                ? QuestionDifficulty.medium 
                : QuestionDifficulty.easy;
        return Question(pq.questionText, difficulty);
      }).toList();
      
      // Populate answers if they already submitted
      for (int i = 0; i < existingQuestions.length; i++) {
        answers[i] = existingQuestions[i].answer;
        controllers[i]?.text = existingQuestions[i].answer;
      }
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _questionsInitialized = true;
          });
        }
      });
    }
  }

  Future<void> _deleteGameAndReturnToLobby() async {
    try {
      final gameService = GameService();
      await gameService.deleteGame(widget.gameId);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting game: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService();
    final playerService = PlayerService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<Game?>(
      stream: gameService.watchGame(widget.gameId),
      builder: (context, gameSnapshot) {
        final game = gameSnapshot.data;
        final isOwner = game != null && game.creatorId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Phase 1: Answer Questions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: isOwner
                ? [
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.tertiary),
                      onPressed: _deleteGameAndReturnToLobby,
                      tooltip: 'Delete game and return to lobby',
                    ),
                  ]
                : null,
          ),
          body: Stack(
            children: [
              Builder(
                builder: (context) {
                  if (!gameSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final game = gameSnapshot.data!;

                  if (game.state == GameState.game && !_hasNavigatedToCountdown) {
                    _hasNavigatedToCountdown = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CountdownScreen(
                            title: "Let's play!",
                            onComplete: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GameScreen(gameId: widget.gameId),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    });
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<Player>>(
                    stream: playerService.watchPlayers(widget.gameId),
                    builder: (context, playersSnapshot) {
                      if (!playersSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final players = playersSnapshot.data!;
                      final currentPlayer = players.firstWhere(
                        (p) => p.userId == currentUserId,
                      );
                      final completedCount =
                          players.where((p) => p.hasCompletedQuestionnaire).length;

                      if (!_questionsInitialized) {
                        _initializeQuestions(currentPlayer.id, game, players);
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (currentPlayer.hasCompletedQuestionnaire) {
                        final isAdmin = game.creatorId == currentUserId;
                        final adminPlayer = players.firstWhere(
                          (p) => p.userId == game.creatorId,
                        );

                        return Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 800,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 64, color: Colors.green),
                                const SizedBox(height: 16),
                                Text(
                                  'Waiting for other players...',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Players completed: $completedCount/${players.length}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 32),
                                if (isAdmin)
                                  ElevatedButton(
                                    onPressed: _isStartingGame
                                        ? null
                                        : () => _startGameAsAdmin(game, players),
                                    child: const Text('Start Game'),
                                  )
                                else
                                  Text(
                                    'Waiting for ${adminPlayer.username} to start the game',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 800,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 32,),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Question ${_currentPage + 1} of 6',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.tertiary,
                                      color: Theme.of(context).colorScheme.secondary,
                                      value: (_currentPage + 1) / 6,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemCount: 6,
                                  itemBuilder: (context, index) {
                                    final question = _selectedQuestions[index];
                                    return Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            question.text,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 32),
                                          TextField(
                                            controller: controllers[index],
                                            decoration: const InputDecoration(
                                              hintText: 'Your answer',
                                              border: OutlineInputBorder(),
                                            ),
                                            autofocus: true,
                                            textInputAction: TextInputAction.done,
                                            onChanged: (value) {
                                              setState(() {
                                                answers[index] = value.trim();
                                              });
                                            },
                                            onSubmitted: (_) {
                                              if (_currentQuestionAnswered()) {
                                                if (_currentPage < 5) {
                                                  _goToNextQuestion();
                                                } else {
                                                  _submitAnswers(
                                                      currentPlayer.id, players, game);
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_currentPage > 0)
                                      TextButton.icon(
                                        onPressed: () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Back'),
                                      )
                                    else
                                      const SizedBox(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 48,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _currentQuestionAnswered()
                                            ? () {
                                                if (_currentPage < 5) {
                                                  _goToNextQuestion();
                                                } else {
                                                  _submitAnswers(
                                                      currentPlayer.id, players, game);
                                                }
                                              }
                                            : null,
                                        child: Text(
                                          _currentPage < 5 ? 'Next' : 'Submit',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              IgnorePointer(
                ignoring: !_isStartingGame,
                child: AnimatedOpacity(
                  opacity: _isStartingGame ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: const LoadingOverlay(
                    message: '✨ Gathering stardust... preparing questions all about you ✨',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitAnswers(
      String playerId, List<Player> players, Game game) async {
    if (answers.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    try {
      print('[QuestionnaireScreen] _submitAnswers - START - playerId: $playerId, gameId: ${widget.gameId}');
      
      final playerQuestions = <PlayerQuestion>[];
      for (int i = 0; i < 6; i++) {
        final question = _selectedQuestions[i];
        final answer = answers[i] ?? '';
        final difficulty = question.difficulty == QuestionDifficulty.hard 
            ? 'hard' 
            : question.difficulty == QuestionDifficulty.medium 
                ? 'medium' 
                : 'easy';
        
        playerQuestions.add(PlayerQuestion(
          id: '', // Will be set by the service
          questionText: question.text,
          answer: answer,
          difficulty: difficulty,
          order: i,
          createdAt: DateTime.now(),
        ));
      }
      
      final playerQuestionService = PlayerQuestionService();
      await playerQuestionService.savePlayerQuestions(
        gameId: widget.gameId,
        playerId: playerId,
        questions: playerQuestions,
      );
      print('[QuestionnaireScreen] _submitAnswers - Player questions saved successfully');

      final playerService = PlayerService();
      await playerService.updateQuestionnaireStatus(widget.gameId, playerId, true);
      print('[QuestionnaireScreen] _submitAnswers - SUCCESS');
    } catch (e, stackTrace) {
      print('[QuestionnaireScreen] _submitAnswers - ERROR: $e');
      print('[QuestionnaireScreen] _submitAnswers - STACK TRACE: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answers: $e')),
        );
      }
    }
  }

  Future<void> _startGameAsAdmin(Game game, List<Player> players) async {
    print('[QuestionnaireScreen] _startGameAsAdmin - START - gameId: ${widget.gameId}, players count: ${players.length}');
    
    setState(() {
      _isStartingGame = true;
    });

    try {
      final gameService = GameService();
      final playerQuestionService = PlayerQuestionService();
      final roundQuestionsService = RoundQuestionsService();
      
      // Randomize player order for rounds
      print('[QuestionnaireScreen] _startGameAsAdmin - Randomizing player order');
      final playerIdsList = players.map((p) => p.id).toList();
      print('[QuestionnaireScreen] _startGameAsAdmin - Player IDs: $playerIdsList');
      
      // Shuffle the list first before choosing round order
      playerIdsList.shuffle();
      print('[QuestionnaireScreen] _startGameAsAdmin - Shuffled player IDs: $playerIdsList');
      
      // Apply numberOfRounds limit if specified, otherwise use all players
      // Cap at player count if numberOfRounds exceeds number of players
      final requestedRounds = game.numberOfRounds ?? playerIdsList.length;
      final numberOfRounds = requestedRounds > playerIdsList.length ? playerIdsList.length : requestedRounds;
      final roundOrder = playerIdsList.take(numberOfRounds).toList();
      print('[QuestionnaireScreen] _startGameAsAdmin - Number of rounds: $numberOfRounds (requested: $requestedRounds, players: ${playerIdsList.length})');
      print('[QuestionnaireScreen] _startGameAsAdmin - Round order: $roundOrder');
      
      await gameService.setRoundOrder(widget.gameId, roundOrder);
      print('[QuestionnaireScreen] _startGameAsAdmin - Round order set successfully');
      
      // Create round_questions for each round upfront
      print('[QuestionnaireScreen] _startGameAsAdmin - Creating round_questions for ${roundOrder.length} rounds');
      for (int round = 0; round < roundOrder.length; round++) {
        final targetPlayerId = roundOrder[round];
        print('[QuestionnaireScreen] _startGameAsAdmin - Round $round: target player ID: $targetPlayerId');
        
        final targetPlayer = players.firstWhere(
          (p) => p.id == targetPlayerId,
          orElse: () {
            print('[QuestionnaireScreen] _startGameAsAdmin - ERROR: Target player not found in players list - targetPlayerId: $targetPlayerId');
            throw Exception('Player not found: $targetPlayerId');
          },
        );
        print('[QuestionnaireScreen] _startGameAsAdmin - Round $round: target player found - ${targetPlayer.username}');
        
        final playerQuestions = await playerQuestionService.getPlayerQuestions(widget.gameId, targetPlayerId);
        if (playerQuestions.isEmpty) {
          print('[QuestionnaireScreen] _startGameAsAdmin - ERROR: No questions found for player - targetPlayerId: $targetPlayerId');
          throw Exception('No questions found for player: $targetPlayerId');
        }
        print('[QuestionnaireScreen] _startGameAsAdmin - Round $round: player questions found - count: ${playerQuestions.length}');
        
        await roundQuestionsService.createRoundQuestions(
          gameId: widget.gameId,
          round: round,
          playerQuestions: playerQuestions,
        );
        print('[QuestionnaireScreen] _startGameAsAdmin - Round $round: round_questions created successfully');
      }
      
      // Start the game
      print('[QuestionnaireScreen] _startGameAsAdmin - Updating game state to "game"');
      await gameService.updateGameState(widget.gameId, GameState.game);
      print('[QuestionnaireScreen] _startGameAsAdmin - Setting current round to 0');
      await gameService.updateCurrentRound(widget.gameId, 0);
      print('[QuestionnaireScreen] _startGameAsAdmin - SUCCESS');
    } catch (e, stackTrace) {
      print('[QuestionnaireScreen] _startGameAsAdmin - ERROR: $e');
      print('[QuestionnaireScreen] _startGameAsAdmin - STACK TRACE: $stackTrace');
      if (mounted) {
        setState(() {
          _isStartingGame = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e')),
        );
      }
    }
  }
}
