import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/models/guess.dart';
import 'package:whodis/models/round_questions.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/guess_service.dart';
import 'package:whodis/services/round_questions_service.dart';
import 'package:whodis/screens/reveal_answers.dart';
import 'package:whodis/screens/countdown_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _syncTimer;
  bool _isAdmin = false;
  Timer? _adminQuestionTimer;
  bool _endingTriggered = false;

  @override
  void initState() {
    super.initState();
    // Start a timer to periodically update the UI to reflect server time
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _adminQuestionTimer?.cancel();
    super.dispose();
  }

  void _startAdminTimer(int totalPlayers, int currentRound, int totalQuestions,
      int timerDuration) async {
    _adminQuestionTimer?.cancel();
    final gameService = GameService();

    _adminQuestionTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final game = await gameService.getGame(widget.gameId);
      if (game == null || !mounted) {
        timer.cancel();
        _adminQuestionTimer = null;
        return;
      }

      // Stop timer if we are ending or finished to avoid duplicate triggers
      if (game.endingGame || game.state == GameState.finished) {
        timer.cancel();
        _adminQuestionTimer = null;
        return;
      }

      final currentQuestionIndex = game.currentQuestionIndex ?? 0;
      final questionStartTime = game.questionStartTime;

      if (questionStartTime == null) return;

      final elapsed = DateTime.now().difference(questionStartTime).inSeconds;
      final timeRemaining = timerDuration - elapsed;

      if (timeRemaining <= 0) {
        if (currentQuestionIndex < totalQuestions - 1) {
          await gameService.advanceQuestion(
              widget.gameId, currentQuestionIndex + 1);
        } else {
          timer.cancel();
          _adminQuestionTimer = null;
          await _handleRoundEnd(totalPlayers, currentRound);
        }
      }
    });
  }

  int _calculateTimeRemaining(DateTime? questionStartTime, int timerDuration) {
    if (questionStartTime == null) return timerDuration;
    final elapsed = DateTime.now().difference(questionStartTime).inSeconds;
    return (timerDuration - elapsed).clamp(0, timerDuration);
  }

  Future<void> _handleRoundEnd(int totalPlayers, int currentRound) async {
    final gameService = GameService();
    
    // Award target player (player the round is about) the average score of others
    await _awardTargetPlayerScore(currentRound);

    if (currentRound < totalPlayers - 1) {
      await gameService.setBetweenRounds(widget.gameId, true);
    } else {
      // Guard against duplicate end-game triggers
      if (!_endingTriggered) {
        _endingTriggered = true;
        await gameService.setEndingGame(widget.gameId, true);
      }
    }
  }

  Future<void> _awardTargetPlayerScore(int currentRound) async {
    try {
      final game = await GameService().getGame(widget.gameId);
      if (game == null || game.roundOrder.isEmpty) return;

      final targetPlayerId = game.roundOrder[currentRound];
      
      // Get all guesses for this round
      final guessService = GuessService();
      final guesses = await guessService.getGuessesForRound(widget.gameId, currentRound);
      
      // Calculate total points earned by all players (excluding target player)
      int totalPoints = 0;
      int guesserCount = 0;
      
      final guessesGroupedByPlayer = <String, List<Guess>>{};
      for (var guess in guesses) {
        if (guess.guesserId != targetPlayerId) {
          guessesGroupedByPlayer.putIfAbsent(guess.guesserId, () => []).add(guess);
        }
      }
      
      // For each guesser, find their first correct guess and award points
      for (var entry in guessesGroupedByPlayer.entries) {
        final playerGuesses = entry.value;
        playerGuesses.sort((a, b) => a.guessNumber.compareTo(b.guessNumber));
        
        for (var guess in playerGuesses) {
          if (guess.targetPlayerId == targetPlayerId) {
            // This is a correct guess
            final points = _calculatePoints(guess.questionIndex, guess.guessNumber);
            totalPoints += points;
            guesserCount++;
            break; // Only count first correct guess per player
          }
        }
      }
      
      // Award average points to target player
      if (guesserCount > 0) {
        final averagePoints = (totalPoints / guesserCount).round();
        await PlayerService().updateScore(widget.gameId, targetPlayerId, averagePoints, round: currentRound);
        print('[GameScreen] Awarded $averagePoints points to target player $targetPlayerId (average of $totalPoints from $guesserCount players)');
      }
    } catch (e) {
      print('[GameScreen] Error awarding target player score: $e');
    }
  }

  Future<void> _advanceToNextRound(int currentRound) async {
    final gameService = GameService();
    await gameService.updateCurrentRound(widget.gameId, currentRound + 1);
  }

  int _calculatePoints(int questionIndex, int guessNumber) {
    final basePoints = (6 - questionIndex);
    if (guessNumber == 1) return basePoints * 3;
    if (guessNumber == 2) return basePoints * 2;
    if (guessNumber == 3) return basePoints * 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService();
    final playerService = PlayerService();
    final guessService = GuessService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<Game?>(
        stream: gameService.watchGame(widget.gameId),
        builder: (context, gameSnapshot) {
          if (!gameSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = gameSnapshot.data!;
          _isAdmin = game.creatorId == currentUserId;

          if (game.endingGame) {
            return CountdownScreen(
              title: "All done! Let's go to the results",
              onComplete: () async {
                if (_isAdmin) {
                  final svc = GameService();
                  await svc.setEndingGame(widget.gameId, false);
                  await svc.updateGameState(widget.gameId, GameState.finished);
                }
              },
            );
          }

          if (game.state == GameState.finished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RevealAnswersScreen(gameId: widget.gameId),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          final currentRound = game.currentRound ?? 0;
          final roundQuestionsService = RoundQuestionsService();

          if (game.betweenRounds) {
            return CountdownScreen(
              title: 'Get ready for the next round!',
              onComplete: () {
                if (_isAdmin) {
                  _advanceToNextRound(currentRound);
                }
              },
            );
          }

          return StreamBuilder<List<Player>>(
            stream: playerService.watchPlayers(widget.gameId),
            builder: (context, playersSnapshot) {
              if (!playersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final players = playersSnapshot.data!;

              // Safety check: ensure currentRound is within bounds
              if (currentRound >= game.roundOrder.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentPlayer =
                  players.firstWhere((p) => p.userId == currentUserId);
              final targetPlayerId = game.roundOrder[currentRound];
              final targetPlayer =
                  players.firstWhere((p) => p.id == targetPlayerId);

              return StreamBuilder<RoundQuestions?>(
                stream: roundQuestionsService.watchRoundQuestions(
                    widget.gameId, currentRound),
                builder: (context, roundQuestionsSnapshot) {
                  if (!roundQuestionsSnapshot.hasData ||
                      roundQuestionsSnapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final roundQuestions = roundQuestionsSnapshot.data!;
                  final questions = roundQuestions.questions;

                  // Start admin timer if user is admin and timer not running
                  if (_isAdmin && game.questionStartTime != null && !game.endingGame && game.state == GameState.game) {
                    if (_adminQuestionTimer == null ||
                        !_adminQuestionTimer!.isActive) {
                      // Timer started but countdown not running, start it
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _startAdminTimer(players.length, currentRound,
                              questions.length, game.timerDuration);
                        }
                      });
                    }
                  }

                  final currentQuestionIndex = game.currentQuestionIndex ?? 0;
                  final timeRemaining = _calculateTimeRemaining(
                      game.questionStartTime, game.timerDuration);
                  final revealedQuestions =
                      List.generate(currentQuestionIndex + 1, (i) => i).toSet();

                  return StreamBuilder<List<Guess>>(
                    stream:
                        guessService.watchGuesses(widget.gameId, currentRound),
                    builder: (context, guessesSnapshot) {
                      final allGuesses = guessesSnapshot.data ?? [];
                      final myGuessesThisRound = allGuesses
                          .where((g) => g.guesserId == currentPlayer.id)
                          .toList();
                      final myGuessesThisQuestion = myGuessesThisRound
                          .where((g) => g.questionIndex == currentQuestionIndex)
                          .toList();
                      final guessCount = myGuessesThisRound.length;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWideScreen = constraints.maxWidth > 900;

                          return Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: isWideScreen ? 1200 : 800,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Round ${currentRound + 1} of ${players.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                        Text(
                                          '$timeRemaining',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: timeRemaining <= 5
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .secondary
                                                    : null,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (currentPlayer.id != targetPlayer.id)
                                          Text(
                                            'Guesses: $guessCount/3',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                      ],
                                    ),
                                    if (!isWideScreen) ...[
                                      const SizedBox(height: 32),
                                      Text(
                                        currentPlayer.id == targetPlayer.id
                                            ? 'You dis!'
                                            : 'Who dis?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                    ],
                                    if (currentPlayer.id == targetPlayer.id &&
                                        !isWideScreen) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'This round is all about you. Kick back and relax!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: isWideScreen
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: SingleChildScrollView(
                                                    child: QuestionsBlock(
                                                      revealedQuestions:
                                                          revealedQuestions,
                                                      questions: questions,
                                                      answers: roundQuestions
                                                          .answers,
                                                      allGuesses: allGuesses,
                                                      players: players,
                                                      targetPlayer:
                                                          targetPlayer,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 24),
                                                Expanded(
                                                  flex: 1,
                                                  child: currentPlayer.id !=
                                                          targetPlayer.id
                                                      ? SingleChildScrollView(
                                                          child:
                                                              GuessPlayersSection(
                                                            players: players,
                                                            targetPlayer:
                                                                targetPlayer,
                                                            currentPlayer:
                                                                currentPlayer,
                                                            myGuessesThisRound:
                                                                myGuessesThisRound,
                                                            myGuessesThisQuestion:
                                                                myGuessesThisQuestion,
                                                            guessCount:
                                                                guessCount,
                                                            currentQuestionIndex:
                                                                currentQuestionIndex,
                                                            timerDuration: game
                                                                .timerDuration,
                                                            onPlayerTap:
                                                                (playerId) =>
                                                                    _submitGuess(
                                                              currentPlayer.id,
                                                              targetPlayer.id,
                                                              currentRound,
                                                              playerId,
                                                              currentQuestionIndex,
                                                              guessCount,
                                                              guessService,
                                                              playerService,
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Column(
                                                            children: [
                                                              if (isWideScreen) ...[
                                                                const SizedBox(
                                                                    height: 32),
                                                                Text(
                                                                  currentPlayer
                                                                              .id ==
                                                                          targetPlayer
                                                                              .id
                                                                      ? 'You dis!'
                                                                      : 'Who dis?',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .headlineMedium,
                                                                ),
                                                              ],
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        16.0),
                                                                child: Text(
                                                                  'This round is all about you. Kick back and relax!',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyLarge!,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            )
                                          : SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  QuestionsBlock(
                                                    revealedQuestions:
                                                        revealedQuestions,
                                                    questions: questions,
                                                    answers:
                                                        roundQuestions.answers,
                                                    allGuesses: allGuesses,
                                                    players: players,
                                                    targetPlayer: targetPlayer,
                                                  ),
                                                  if (currentPlayer.id !=
                                                      targetPlayer.id)
                                                    GuessPlayersSection(
                                                      players: players,
                                                      targetPlayer:
                                                          targetPlayer,
                                                      currentPlayer:
                                                          currentPlayer,
                                                      myGuessesThisRound:
                                                          myGuessesThisRound,
                                                      myGuessesThisQuestion:
                                                          myGuessesThisQuestion,
                                                      guessCount: guessCount,
                                                      currentQuestionIndex:
                                                          currentQuestionIndex,
                                                      timerDuration:
                                                          game.timerDuration,
                                                      onPlayerTap: (playerId) =>
                                                          _submitGuess(
                                                        currentPlayer.id,
                                                        targetPlayer.id,
                                                        currentRound,
                                                        playerId,
                                                        currentQuestionIndex,
                                                        guessCount,
                                                        guessService,
                                                        playerService,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitGuess(
    String guesserId,
    String targetPlayerId,
    int currentRound,
    String selectedPlayerId,
    int currentQuestionIndex,
    int guessCount,
    GuessService guessService,
    PlayerService playerService,
  ) async {
    try {
      await guessService.saveGuess(
        gameId: widget.gameId,
        round: currentRound,
        guesserId: guesserId,
        targetPlayerId: selectedPlayerId,
        questionIndex: currentQuestionIndex,
        guessNumber: guessCount + 1,
      );

      if (selectedPlayerId == targetPlayerId) {
        final points = _calculatePoints(currentQuestionIndex, guessCount + 1);
        await playerService.updateScore(widget.gameId, guesserId, points, round: currentRound);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting guess: $e')),
        );
      }
    }
  }
}

class QuestionsBlock extends StatelessWidget {
  final Set<int> revealedQuestions;
  final List<String> questions;
  final List<String> answers;
  final List<Guess> allGuesses;
  final List<Player> players;
  final Player targetPlayer;

  const QuestionsBlock({
    super.key,
    required this.revealedQuestions,
    required this.questions,
    required this.answers,
    required this.allGuesses,
    required this.players,
    required this.targetPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(6, (questionIdx) {
        final isRevealed = revealedQuestions.contains(questionIdx);
        final questionText = isRevealed && questionIdx < questions.length
            ? questions[questionIdx].trim()
            : '';
        final answerText = isRevealed && questionIdx < answers.length
            ? answers[questionIdx]
            : '';
        final questionGuesses = allGuesses
            .where((g) =>
                g.questionIndex == questionIdx &&
                g.guesserId != targetPlayer.id &&
                g.targetPlayerId != null)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(seconds: 1),
                          switchInCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          layoutBuilder: (currentChild, previousChildren) => Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          ),
                          child: isRevealed
                              ? Text(
                                  questionText,
                                  key: ValueKey('q_$questionIdx'),
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                )
                              : SizedBox(height: 20, key: ValueKey('q_placeholder_$questionIdx')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isRevealed)
                        ...questionGuesses.map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: g.guessNumber == 1
                                  ? Colors.amber
                                  : g.guessNumber == 2
                                      ? Colors.grey[400]
                                      : Colors.brown[400],
                              child: Text(
                                '${g.guessNumber}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(seconds: 1),
                    switchInCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: isRevealed
                        ? Text(
                            answerText,
                            key: ValueKey('a_$questionIdx'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                          )
                        : SizedBox.shrink(key: ValueKey('a_placeholder_$questionIdx')),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class GuessPlayersSection extends StatefulWidget {
  final List<Player> players;
  final Player targetPlayer;
  final Player currentPlayer;
  final List<Guess> myGuessesThisRound;
  final List<Guess> myGuessesThisQuestion;
  final int guessCount;
  final int currentQuestionIndex;
  final int timerDuration;
  final Function(String playerId) onPlayerTap;

  const GuessPlayersSection({
    super.key,
    required this.players,
    required this.targetPlayer,
    required this.currentPlayer,
    required this.myGuessesThisRound,
    required this.myGuessesThisQuestion,
    required this.guessCount,
    required this.currentQuestionIndex,
    required this.timerDuration,
    required this.onPlayerTap,
  });

  @override
  State<GuessPlayersSection> createState() => _GuessPlayersSectionState();
}

class _GuessPlayersSectionState extends State<GuessPlayersSection> {
  String? _hoveredPlayerId;

  @override
  Widget build(BuildContext context) {
    final otherPlayers =
        widget.players.where((p) => p.id != widget.currentPlayer.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who Dis?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...otherPlayers.map((player) {
          final guessForPlayerInRound = widget.myGuessesThisRound.firstWhere(
            (g) => g.targetPlayerId == player.id,
            orElse: () => Guess(
              id: '',
              round: 0,
              guesserId: '',
              questionIndex: 0,
              guessNumber: 0,
              createdAt: DateTime.now(),
            ),
          );
          final hasGuessedThisPlayer = guessForPlayerInRound.guessNumber > 0;
          final hasGuessedThisQuestion =
              widget.myGuessesThisQuestion.isNotEmpty;
          final canGuess = !hasGuessedThisPlayer &&
              !hasGuessedThisQuestion &&
              widget.guessCount < 3;
          final isHovered = _hoveredPlayerId == player.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: MouseRegion(
                cursor: canGuess
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: canGuess
                    ? (_) => setState(() => _hoveredPlayerId = player.id)
                    : null,
                onExit: canGuess
                    ? (_) => setState(() => _hoveredPlayerId = null)
                    : null,
                child: ListTile(
                  tileColor: isHovered && canGuess
                      ? Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: hasGuessedThisPlayer
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    player.username,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: hasGuessedThisPlayer
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.tertiary,
                        ),
                  ),
                  trailing: hasGuessedThisPlayer
                      ? CircleAvatar(
                          radius: 16,
                          child: Text(
                              'Q${guessForPlayerInRound.questionIndex + 1}'),
                        )
                      : null,
                  onTap: canGuess ? () => widget.onPlayerTap(player.id) : null,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
