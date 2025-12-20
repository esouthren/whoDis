import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/firebase_options.dart';
import 'package:whodis/theme.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/models/user.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/user_service.dart';
import 'package:whodis/screens/start_screen.dart';
import 'package:whodis/screens/lobby_screen.dart';
import 'package:whodis/screens/questionnaire_screen.dart';
import 'package:whodis/screens/game_screen.dart';
import 'package:whodis/screens/reveal_answers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Who Dis?',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.light,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const StartScreen();
        }
        
        return GameStateRouter(userId: user.uid);
      },
    );
  }
}

class GameStateRouter extends StatelessWidget {
  final String userId;

  const GameStateRouter({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final gameService = GameService();

    return StreamBuilder<AppUser?>(
      stream: userService.watchUser(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final appUser = userSnapshot.data;
        final activeGameId = appUser?.activeGame;

        if (activeGameId == null) {
          return const StartScreen();
        }

        return StreamBuilder<Game?>(
          stream: gameService.watchGame(activeGameId),
          builder: (context, gameSnapshot) {
            if (gameSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final game = gameSnapshot.data;

            if (game == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await userService.setActiveGame(userId, null);
              });
              return const StartScreen();
            }

            final gameAge = DateTime.now().difference(game.createdAt);
            final isGameTooOld = gameAge.inHours >= 1;

            if (isGameTooOld) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await userService.setActiveGame(userId, null);
              });
              return const StartScreen();
            }

            return _routeToGameScreen(game);
          },
        );
      },
    );
  }

  Widget _routeToGameScreen(Game game) {
    switch (game.state) {
      case GameState.starting:
      case GameState.lobby:
        return LobbyScreen(gameId: game.id);
      case GameState.questionnaire:
        return QuestionnaireScreen(gameId: game.id);
      case GameState.game:
        return GameScreen(gameId: game.id);
      case GameState.finished:
        return RevealAnswersScreen(gameId: game.id);
    }
  }
}
