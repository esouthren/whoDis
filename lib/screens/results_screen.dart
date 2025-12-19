import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/user_service.dart';

enum ImageSize {
  large(450),
  medium(350),
  small(300);

  final double size;
  const ImageSize(this.size);
}

class ResultsScreen extends StatefulWidget {
  final String gameId;

  const ResultsScreen({super.key, required this.gameId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[ResultsScreen] init gameId=${widget.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    final playerService = PlayerService();
    final gameService = GameService();

    return Scaffold(
      body: StreamBuilder<List<Player>>(
        stream: playerService.watchPlayers(widget.gameId),
        builder: (context, snapshot) {
          debugPrint(
              '[ResultsScreen] stream state=${snapshot.connectionState} hasData=${snapshot.hasData} hasError=${snapshot.hasError}');
          if (snapshot.hasError) {
            debugPrint(
                '[ResultsScreen] players stream error: ${snapshot.error}');
            return const Center(child: Text('Failed to load results'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = [
            ...snapshot.data!,
          ];
          debugPrint(
              '[ResultsScreen] players received count=${players.length}');
          for (var i = 0; i < players.length; i++) {
            final p = players[i];
            debugPrint(
                '[ResultsScreen] player ${i + 1}: name=${p.username} score=${p.score} imageURL=${p.image}');
          }
          if (players.isEmpty) {
            debugPrint(
                '[ResultsScreen] no players found for gameId=${widget.gameId}');
            return const Center(child: Text('No players'));
          }

          players.sort((a, b) => b.score.compareTo(a.score));

          final firstPlayer = players.isNotEmpty ? players[0] : null;
          final secondAndThird = players.length >= 2
              ? players.sublist(1, players.length >= 3 ? 3 : 2)
              : <Player>[];
          final remainingPlayers =
              players.length > 3 ? players.sublist(3) : <Player>[];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                        child: Text(
                          'Final Results',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (firstPlayer != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlayerResultCard(
                            position: 1,
                            player: firstPlayer,
                            imageSize: ImageSize.large,
                          ),
                        ),
                      if (secondAndThird.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _PlayerResultCard(
                                    position: 2,
                                    player: secondAndThird[0],
                                    imageSize: ImageSize.medium,
                                  ),
                                ),
                              ),
                              if (secondAndThird.length > 1)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _PlayerResultCard(
                                      position: 3,
                                      player: secondAndThird[1],
                                      imageSize: ImageSize.medium,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (remainingPlayers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            height: 400,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: remainingPlayers.length,
                              itemBuilder: (context, index) {
                                final player = remainingPlayers[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < remainingPlayers.length - 1
                                        ? 16
                                        : 0,
                                  ),
                                  child: SizedBox(
                                    width: 350,
                                    child: _PlayerResultCard(
                                      position: 4 + index,
                                      player: player,
                                      imageSize: ImageSize.small,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentUserId =
                            FirebaseAuth.instance.currentUser?.uid;
                        if (currentUserId != null) {
                          await UserService()
                              .setActiveGame(currentUserId, null);
                        }
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                        await gameService.deleteGame(widget.gameId);
                      },
                      child: const Text('Back to Lobby'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerResultCard extends StatelessWidget {
  final int position;
  final Player player;
  final ImageSize imageSize;

  const _PlayerResultCard({
    required this.position,
    required this.player,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = imageSize == ImageSize.large ? 24.0 : 16.0;
    final imageSizeValue = imageSize.size;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: imageSizeValue,
              height: imageSizeValue,
              child: _PlayerImage(imageUrl: player.image),
            ),
          ),
          const SizedBox(height: 16),
          position >= 4
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        player.username,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize:
                              ((theme.textTheme.titleLarge?.fontSize ?? 20) *
                                  0.8),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#$position',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${player.score} pts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.8,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.username,
                      style: (imageSize == ImageSize.large
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
                        fontSize: position >= 4
                            ? ((imageSize == ImageSize.large
                                            ? theme.textTheme.headlineSmall
                                            : theme.textTheme.titleLarge)
                                        ?.fontSize ??
                                    20) *
                                0.8
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#$position',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: position >= 4
                                ? (theme.textTheme.titleMedium?.fontSize ??
                                        16) *
                                    0.8
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${player.score} pts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: position >= 4
                                ? (theme.textTheme.titleMedium?.fontSize ??
                                        16) *
                                    0.8
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _PlayerImage extends StatelessWidget {
  final String? imageUrl;
  const _PlayerImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        child: Center(
          child: Icon(
            Icons.person,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }
    debugPrint('[ResultsScreen] _PlayerImage build url=$imageUrl');
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final expected = loadingProgress.expectedTotalBytes;
        final loaded = loadingProgress.cumulativeBytesLoaded;
        debugPrint(
            '[ResultsScreen] loading image ${imageUrl} loaded=$loaded expected=$expected');
        return Container(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: Icon(
            Icons.downloading,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      },
      errorBuilder: (_, __, error) {
        debugPrint('[ResultsScreen] image error for ${imageUrl}: $error');
        return Container(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      },
    );
  }
}
