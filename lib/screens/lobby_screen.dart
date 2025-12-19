import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/user_service.dart';
import 'package:whodis/screens/questionnaire_screen.dart';
import 'package:whodis/screens/countdown_screen.dart';
import 'package:whodis/services/player_question_service.dart';
import 'package:whodis/services/question_generation_service.dart';
import 'package:whodis/models/player_question.dart';

class LobbyScreen extends StatefulWidget {
  final String gameId;

  const LobbyScreen({super.key, required this.gameId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with SingleTickerProviderStateMixin {
  bool _hasNavigatedToCountdown = false;
  bool _isPreparingQuestions = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService();
    final playerService = PlayerService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Lobby',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app,
                color: Theme.of(context).colorScheme.tertiary),
            onPressed: () =>
                _leaveGame(context, gameService, playerService, currentUserId),
            tooltip: 'Leave Game',
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<Game?>(
            stream: gameService.watchGame(widget.gameId),
            builder: (context, gameSnapshot) {
              if (!gameSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final game = gameSnapshot.data!;

              if (game.state == GameState.questionnaire &&
                  !_hasNavigatedToCountdown) {
                _hasNavigatedToCountdown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CountdownScreen(
                        title: "First, let's get to know you",
                        onComplete: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuestionnaireScreen(gameId: widget.gameId),
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
                  final isCreator = game.creatorId == currentUserId;

                  return Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Game Password: ${game.password}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  onPressed: () => _copyPassword(context, game.password),
                                  tooltip: 'Copy password',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Players',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How to Play',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(context, '1', 'Pre-game: Answer some questions about yourself'),
                                  _buildInstructionStep(context, '2', 'Each round, guess the player from their question set'),
                                  _buildInstructionStep(context, '3', 'You have three guesses for each round'),
                                  _buildInstructionStep(context, '4', 'A new question will be shown every ${game.timerDuration} seconds'),
                                  _buildInstructionStep(context, '5', 'Earn points for guessing as early as possible'),
                                  _buildInstructionStep(context, '6', 'The player with the most points wins!'),
                                ],
                              ),
                            ),

                            if (isCreator && players.length >= 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ElevatedButton(
                                  onPressed: _isPreparingQuestions ? null : () => _startGame(context, gameService),
                                  child: const Text('Start Game'),
                                ),
                              ),
                            const SizedBox(
                              height: 32,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: players.length,
                                itemBuilder: (context, index) => Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(
                                      players[index].username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary),
                                    ),
                                    trailing:
                                        players[index].userId == game.creatorId
                                            ? Text(
                                                'Game Owner',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                              )
                                            : null,
                                  ),
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
          ),
          IgnorePointer(
            ignoring: !_isPreparingQuestions,
            child: AnimatedOpacity(
              opacity: _isPreparingQuestions ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor, // solid background to hide content
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: _fade,
                  child: Text(
                    '✨ Preparing questions all about you ✨',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startGame(BuildContext context, GameService gameService) async {
    setState(() => _isPreparingQuestions = true);
    _fadeController.repeat(reverse: true);
    try {
      debugPrint('[LobbyScreen] Start Game: preparing questions for all players');
      // Fetch all players in the game
      final playersSnap = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('players')
          .get();
      final players = playersSnap.docs
          .map((d) => Player.fromJson(d.data(), d.id))
          .toList();

      final allPlayerIds = players.map((p) => p.id).toList();
      if (allPlayerIds.isEmpty) {
        throw Exception('No players found to generate questions');
      }

      // Generate questions for all players
      final questionsMap = await QuestionGenerationService.generateQuestionsForAllPlayers(
        playerIds: allPlayerIds,
      );

      // Persist questions for each player
      final playerQuestionService = PlayerQuestionService();
      for (final p in players) {
        final generated = questionsMap[p.id] ?? const [];
        if (generated.isEmpty) continue;
        final list = generated.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          return PlayerQuestion(
            id: '',
            questionText: q.text,
            answer: '',
            difficulty: q.difficulty.name,
            order: idx,
            createdAt: DateTime.now(),
          );
        }).toList();
        await playerQuestionService.savePlayerQuestions(
          gameId: widget.gameId,
          playerId: p.id,
          questions: list,
        );
      }

      // Mark on game that questions are generated
      await FirebaseFirestore.instance.collection('games').doc(widget.gameId).update({
        'questions_generated': true,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      // Move to questionnaire phase
      await gameService.updateGameState(widget.gameId, GameState.questionnaire);
    } catch (e) {
      debugPrint('[LobbyScreen] Start Game ERROR: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e')),
        );
      }
    } finally {
      _fadeController.stop();
      if (mounted) setState(() => _isPreparingQuestions = false);
    }
  }

  Future<void> _leaveGame(
    BuildContext context,
    GameService gameService,
    PlayerService playerService,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;

    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('Cancel',  style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
              ),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('Leave',    style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.tertiary,
              ),),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final player =
          await playerService.getPlayerByUserId(widget.gameId, currentUserId);
      if (player != null) {
        await playerService.deletePlayer(widget.gameId, player.id);
      }

      await gameService.leaveGame(widget.gameId, currentUserId);
      
      final userService = UserService();
      await userService.setActiveGame(currentUserId, null);
      
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving game: $e')),
        );
      }
    }
  }

  void _copyPassword(BuildContext context, String password) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
