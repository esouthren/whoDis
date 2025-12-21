import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/models/guess.dart';
import 'package:whodis/models/round_questions.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/guess_service.dart';
import 'package:whodis/services/round_questions_service.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/user_service.dart';
import 'package:whodis/screens/final_scores.dart';

class RevealAnswersScreen extends StatefulWidget {
  final String gameId;

  const RevealAnswersScreen({super.key, required this.gameId});

  @override
  State<RevealAnswersScreen> createState() => _RevealAnswersScreenState();
}

class _RevealAnswersScreenState extends State<RevealAnswersScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isUpdatingPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageWithGame(int? gameResultsPage) {
    if (gameResultsPage != null && gameResultsPage != _currentPage && !_isUpdatingPage) {
      _isUpdatingPage = true;
      _pageController
          .animateToPage(gameResultsPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
          .then((_) => _isUpdatingPage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = PlayerService();
    final guessService = GuessService();
    final roundQuestionsService = RoundQuestionsService();
    final gameService = GameService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Round Answers', style: Theme.of(context).textTheme.headlineMedium),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Back to Lobby',
            onPressed: () async {
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId != null) {
                await UserService().setActiveGame(currentUserId, null);
              }
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<Game?>(
        stream: gameService.watchGame(widget.gameId),
        builder: (context, gameSnapshot) {
          if (!gameSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final game = gameSnapshot.data!;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isAdmin = game.creatorId == currentUserId;

          if (!isAdmin) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _syncPageWithGame(game.currentResultsPage));
          }

          return StreamBuilder<List<Player>>(
            stream: playerService.watchPlayers(widget.gameId),
            builder: (context, playersSnapshot) {
              if (!playersSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final players = [...playersSnapshot.data!];
              players.sort((a, b) => b.score.compareTo(a.score));

              return FutureBuilder<List<Guess>>(
                future: guessService.getAllGuesses(widget.gameId),
                builder: (context, guessesSnapshot) {
                  if (!guessesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final guesses = guessesSnapshot.data!;

                  return FutureBuilder<List<RoundQuestions>>(
                    future: _fetchAllRoundQuestions(roundQuestionsService, players.length),
                    builder: (context, roundQuestionsSnapshot) {
                      if (!roundQuestionsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final allRoundQuestions = roundQuestionsSnapshot.data!;
                      final totalPages = players.length; // one page per round only

                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (page) async {
                                    setState(() => _currentPage = page);
                                    if (isAdmin && !_isUpdatingPage) {
                                      await gameService.updateCurrentResultsPage(widget.gameId, page);
                                    }
                                  },
                                  itemCount: totalPages,
                                  physics: isAdmin ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) => _buildRoundPage(
                                    context,
                                    index,
                                    game,
                                    players,
                                    guesses,
                                    allRoundQuestions,
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_currentPage > 0)
                                        ElevatedButton.icon(
                                          onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Previous'),
                                        )
                                      else
                                        const SizedBox(width: 120),
                                      if (_currentPage < totalPages - 1)
                                        ElevatedButton.icon(
                                          onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                                          icon: const Icon(Icons.arrow_forward),
                                          label: const Text('Next'),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => FinalScoresScreen(gameId: widget.gameId),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.emoji_events),
                                          label: const Text('View Final Scores'),
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
              );
            },
          );
        },
      ),
    );
  }

  Future<List<RoundQuestions>> _fetchAllRoundQuestions(RoundQuestionsService service, int numRounds) async {
    final List<RoundQuestions> allQuestions = [];
    for (int i = 0; i < numRounds; i++) {
      final roundQuestions = await service.getRoundQuestions(widget.gameId, i);
      if (roundQuestions != null) allQuestions.add(roundQuestions);
    }
    return allQuestions;
  }

  Widget _buildRoundPage(
    BuildContext context,
    int roundIndex,
    Game game,
    List<Player> players,
    List<Guess> guesses,
    List<RoundQuestions> allRoundQuestions,
  ) {
    final targetPlayerId = (roundIndex < game.roundOrder.length) ? game.roundOrder[roundIndex] : null;
    final targetPlayer = targetPlayerId != null
        ? players.firstWhere((p) => p.id == targetPlayerId, orElse: () => players.first)
        : players.first;
    final roundGuesses = guesses.where((g) => g.round == roundIndex).toList();
    final roundData = roundIndex < allRoundQuestions.length ? allRoundQuestions[roundIndex] : null;
    final roundQuestions = roundData?.questions ?? <String>[];
    final roundAnswers = roundData?.answers ?? <String>[];

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWideScreen ? double.infinity : 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: isWideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildQuestionsSection(
                        context,
                        roundIndex,
                        game,
                        targetPlayer,
                        roundQuestions,
                        roundAnswers,
                        roundGuesses,
                        players,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 105.0),
                        child: _buildRoundScoresPanel(context, roundIndex, players),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionsSection(
                      context,
                      roundIndex,
                      game,
                      targetPlayer,
                      roundQuestions,
                      roundAnswers,
                      roundGuesses,
                      players,
                    ),
                    const SizedBox(height: 16),
                    _buildRoundScoresPanel(context, roundIndex, players),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuestionsSection(
    BuildContext context,
    int roundIndex,
    Game game,
    Player targetPlayer,
    List<String> roundQuestions,
    List<String> roundAnswers,
    List<Guess> roundGuesses,
    List<Player> players,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text('Round ${roundIndex + 1}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              if (game.revealedRounds.contains(roundIndex))
                Text(
                  'Answer: ${targetPlayer.username}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),
                )
              else if (game.creatorId == FirebaseAuth.instance.currentUser?.uid)
                ElevatedButton(
                  onPressed: () async => GameService().revealRound(widget.gameId, roundIndex),
                  child: const Text('Reveal Answer'),
                )
              else
                StreamBuilder<Game?>(
                  stream: GameService().watchGame(widget.gameId),
                  builder: (context, adminSnapshot) {
                    if (!adminSnapshot.hasData) return const SizedBox.shrink();
                    final adminPlayer = players.firstWhere(
                      (p) => p.id == adminSnapshot.data!.creatorId,
                      orElse: () => players.first,
                    );
                    return ElevatedButton(
                      onPressed: null,
                      child: Text('Waiting for ${adminPlayer.username} to reveal answer'),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ...List.generate(roundQuestions.length, (qIndex) {
          final question = roundQuestions[qIndex];
          final answer = qIndex < roundAnswers.length ? roundAnswers[qIndex] : '';
          final questionGuesses = roundGuesses.where((g) => g.questionIndex == qIndex).toList();

          return Container(
            constraints: const BoxConstraints(maxWidth: 750),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    answer,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  if (questionGuesses.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...questionGuesses.map((guess) {
                      final guesser = players.firstWhere((p) => p.id == guess.guesserId);
                      final isCorrect = guess.targetPlayerId == targetPlayer.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              size: 20,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${guesser.username} guessed ${isCorrect ? 'correctly' : 'incorrectly'} (Guess ${guess.guessNumber})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRoundScoresPanel(BuildContext context, int roundIndex, List<Player> players) {
    final playersWithRoundScores = players
        .map((p) => {'player': p, 'score': p.roundScores[roundIndex] ?? 0})
        .toList();
    playersWithRoundScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Round ${roundIndex + 1} Score', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.normal)),
          const SizedBox(height: 16),
          ...playersWithRoundScores.map((entry) {
            final player = entry['player'] as Player;
            final score = entry['score'] as int;
            final position = playersWithRoundScores.indexOf(entry) + 1;

            return Padding(padding: EdgeInsets.only(bottom: 6.0), child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: position == 1
                        ? Colors.amber
                        : position == 2
                            ? Colors.grey
                            : position == 3
                                ? Colors.brown
                                : Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(player.username, style: Theme.of(context).textTheme.bodyLarge),
                ),
                Text('$score pts', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
              ],
            ),);
          }),
        ],
      ),
    );
  }
}
