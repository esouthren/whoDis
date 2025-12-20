import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/user_service.dart';
import 'package:whodis/utils/open_in_new_tab.dart';

enum ImageSize {
  large(450),
  medium(350),
  small(300);

  final double size;
  const ImageSize(this.size);
}

class FinalScoresScreen extends StatefulWidget {
  final String gameId;

  const FinalScoresScreen({super.key, required this.gameId});

  @override
  State<FinalScoresScreen> createState() => _FinalScoresScreenState();
}

class _FinalScoresScreenState extends State<FinalScoresScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[FinalScoresScreen] init gameId=${widget.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    final playerService = PlayerService();
    final gameService = GameService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Final Results',
            style: Theme.of(context).textTheme.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Player>>(
        stream: playerService.watchPlayers(widget.gameId),
        builder: (context, snapshot) {
          debugPrint(
              '[FinalScoresScreen] stream state=${snapshot.connectionState} hasData=${snapshot.hasData} hasError=${snapshot.hasError}');
          if (snapshot.hasError) {
            debugPrint(
                '[FinalScoresScreen] players stream error: ${snapshot.error}');
            return const Center(child: Text('Failed to load results'));
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final players = [...snapshot.data!];
          debugPrint(
              '[FinalScoresScreen] players received count=${players.length}');
          if (players.isEmpty) return const Center(child: Text('No players'));

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
                      if (firstPlayer != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlayerResultCard(
                              position: 1,
                              player: firstPlayer,
                              imageSize: ImageSize.large),
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
                                      imageSize: ImageSize.medium),
                                ),
                              ),
                              if (secondAndThird.length > 1)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _PlayerResultCard(
                                        position: 3,
                                        player: secondAndThird[1],
                                        imageSize: ImageSize.medium),
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
                                          : 0),
                                  child: SizedBox(
                                    width: 350,
                                    child: _PlayerResultCard(
                                        position: 4 + index,
                                        player: player,
                                        imageSize: ImageSize.small),
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

class _PlayerResultCard extends StatefulWidget {
  final int position;
  final Player player;
  final ImageSize imageSize;

  const _PlayerResultCard(
      {required this.position, required this.player, required this.imageSize});

  @override
  State<_PlayerResultCard> createState() => _PlayerResultCardState();
}

class _PlayerResultCardState extends State<_PlayerResultCard> {
  bool _hovering = false;

  Future<void> _openInNewTab() async {
    final imageUrl = widget.player.image;
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await openImageInNewTab(imageUrl);
    } catch (e) {
      debugPrint('Open in new tab failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to open image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = widget.imageSize == ImageSize.large ? 24.0 : 16.0;
    final imageSizeValue = widget.imageSize.size;

    return Container(
      decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (widget.player.image != null &&
                      widget.player.image!.isNotEmpty)
                  ? _openInNewTab
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    SizedBox(
                        width: imageSizeValue,
                        height: imageSizeValue,
                        child: _PlayerImage(imageUrl: widget.player.image)),
                    if (widget.player.image != null &&
                        widget.player.image!.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: AnimatedOpacity(
                          opacity: _hovering ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle),
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.open_in_new,
                                  color: theme.colorScheme.onSurface, size: 20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          widget.position >= 4
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.player.username,
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontSize:
                                ((theme.textTheme.titleLarge?.fontSize ?? 20) *
                                    0.8)),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('#${widget.position}',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize:
                                (theme.textTheme.titleMedium?.fontSize ?? 16) *
                                    0.8)),
                    const SizedBox(width: 8),
                    Text('${widget.player.score} pts',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize:
                                (theme.textTheme.titleMedium?.fontSize ?? 16) *
                                    0.8)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.player.username,
                      style: (widget.imageSize == ImageSize.large
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleLarge),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('#${widget.position}',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.secondary)),
                        const SizedBox(width: 16),
                        Text('${widget.player.score} pts',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.secondary)),
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
            child: Icon(Icons.person,
                size: 64, color: Theme.of(context).colorScheme.secondary)),
      );
    }
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: Icon(Icons.downloading,
              size: 48, color: Theme.of(context).colorScheme.secondary),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        child: Center(
            child: Icon(Icons.broken_image,
                size: 64, color: Theme.of(context).colorScheme.secondary)),
      ),
    );
  }
}
