import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/game.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/user_service.dart';
import 'package:whodis/screens/lobby_screen.dart';
import 'package:whodis/widgets/buttons.dart';
import 'package:whodis/screens/testing_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _buttonOpacityAnimation;
  User? _currentUser;
  String? _savedUsername;
  bool _isLoading = true;
  bool _isCogHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _buttonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    String? savedUsername;

    if (user != null) {
      final userService = UserService();
      final appUser = await userService.getUser(user.uid);
      savedUsername = appUser?.username;
    }

    setState(() {
      _currentUser = user;
      _savedUsername = savedUsername;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.4;

    return Scaffold(
      appBar: _currentUser != null && !_isLoading
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.secondary),
                  onPressed: _signOut,
                  tooltip: 'Sign Out',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 3.14159,
                          child: SizedBox(
                            height: imageHeight,
                            child: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/xni75w9l4qcdp0p0xnbergczhoxgud.firebasestorage.app/o/whodis.png?alt=media',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.question_mark,
                                size: imageHeight * 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: _buttonOpacityAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _buttonOpacityAnimation.value,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : _currentUser == null
                                ? _buildGoogleSignInButton()
                                : Column(
                                    children: [
                                      PrimaryButton(
                                          onPressed: () => _startGame(context),
                                          text: 'Start Game'),
                                      const SizedBox(height: 16),
                                      SecondaryButton(
                                        onPressed: () =>
                                            _showJoinDialog(context),
                                        text: 'Join Game',
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isCogHovered = true),
              onExit: (_) => setState(() => _isCogHovered = false),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: AnimatedOpacity(
                    opacity: _isCogHovered ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    child: Tooltip(
                      message: 'Top Secret!',
                      child: FloatingActionButton.small(
                        heroTag: 'testingFab',
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TestingScreen(),
                          ),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startGame(BuildContext context) async {
    final usernameController =
        TextEditingController(text: _savedUsername ?? '');
    final timerController = TextEditingController(text: '10');
    final roundsController = TextEditingController();

    final theme = Theme.of(context);

    final result = await showDialog<Map<String, String>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Create New Game',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Name'),
            SizedBox(height: 12),
            TextField(
              controller: usernameController,
              autofocus: true,
            ),
            SizedBox(height: 16),
            Text('Time\u00A0between question reveal (seconds)'),
            SizedBox(height: 12),
            TextField(
              controller: timerController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text('Number of Rounds'),
            SizedBox(height: 12),
            TextField(
              controller: roundsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Leave empty to use # of players',
              ),
              onSubmitted: (_) => Navigator.pop(context, {
                'username': usernameController.text,
                'timer': timerController.text,
                'rounds': roundsController.text,
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'username': usernameController.text,
              'timer': timerController.text,
              'rounds': roundsController.text,
            }),
            child: Text(
              'Create',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null ||
        result['username'] == null ||
        result['username']!.isEmpty) return;

    final username = result['username']!;
    final timerDuration = int.tryParse(result['timer'] ?? '12') ?? 12;
    final numberOfRounds =
        result['rounds'] != null && result['rounds']!.isNotEmpty
            ? int.tryParse(result['rounds']!)
            : null;

    try {
      final userId = _currentUser!.uid;

      final gameService = GameService();
      final game = await gameService.createGame(
        userId,
        timerDuration: timerDuration,
        numberOfRounds: numberOfRounds,
      );

      final playerService = PlayerService();
      await playerService.createPlayer(
        gameId: game.id,
        userId: userId,
        username: username,
        email: _currentUser?.email,
      );

      final userService = UserService();
      await userService.saveUser(userId, username);
      setState(() => _savedUsername = username);

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Game Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this password with your friends:'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.password,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: game.password));
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password copied to clipboard')),
                          );
                        }
                      },
                      tooltip: 'Copy password',
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Set active game - GameStateRouter will handle navigation
                  await userService.setActiveGame(userId, game.id);
                },
                child: Text(
                  'Continue',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e')),
        );
      }
    }
  }

  Future<void> _showJoinDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final usernameController =
        TextEditingController(text: _savedUsername ?? '');
    final theme = Theme.of(context);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Name'),
            SizedBox(height: 12),
            TextField(
              controller: usernameController,
              onSubmitted: (_) => Navigator.pop(context, {
                'password': passwordController.text,
                'username': usernameController.text,
              }),
            ),
            SizedBox(height: 12),
            Text('Game Password'),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              keyboardType: TextInputType.number,
              autofocus: true,
              onSubmitted: (_) => Navigator.pop(context, {
                'password': passwordController.text,
                'username': usernameController.text,
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'password': passwordController.text,
              'username': usernameController.text,
            }),
            child: Text(
              'Join',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null ||
        result['password'] == null ||
        result['password']!.isEmpty ||
        result['username'] == null ||
        result['username']!.isEmpty) return;

    await _joinGame(context, result['password']!, result['username']!);
  }

  Future<void> _joinGame(
      BuildContext context, String password, String username) async {
    if (password.length != 6 || username.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter valid password and username')),
        );
      }
      return;
    }

    try {
      final userId = _currentUser!.uid;

      final gameService = GameService();
      final game = await gameService.getGameByPassword(password);

      if (game == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game not found')),
          );
        }
        return;
      }

      if (game.state != GameState.starting) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game has already started')),
          );
        }
        return;
      }

      if (game.playerIds.length >= 20) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game is full')),
          );
        }
        return;
      }

      await gameService.joinGame(game.id, userId);

      final playerService = PlayerService();
      await playerService.createPlayer(
        gameId: game.id,
        userId: userId,
        username: username,
        email: _currentUser?.email,
      );

      final userService = UserService();
      await userService.saveUser(userId, username);
      await userService.setActiveGame(userId, game.id);
      setState(() => _savedUsername = username);

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LobbyScreen(gameId: game.id),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    }
  }

  Widget _buildGoogleSignInButton() => ElevatedButton(
        onPressed: _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Sign in with Google'),
        ),
      );

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      setState(() => _currentUser = userCredential.user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() => _currentUser = null);
  }
}
