import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whodis/models/player.dart';
import 'package:whodis/services/player_service.dart';
import 'package:whodis/services/game_service.dart';
import 'package:whodis/services/user_service.dart';

class ResultsScreen extends StatefulWidget {
  final String gameId;

  const ResultsScreen({super.key, required this.gameId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index, int max) {
    if (index < 0 || index >= max) return;
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = PlayerService();
    final gameService = GameService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Final Results',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Player>>(
        stream: playerService.watchPlayers(widget.gameId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = [...snapshot.data!];
          if (players.isEmpty) {
            return const Center(child: Text('No players'));
          }

          players.sort((a, b) => b.score.compareTo(a.score));
          final total = players.length;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600,),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final position = index + 1;
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: index == _currentPage ? 1.0 : 0.96,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                          child: UnconstrainedBox(
                            alignment: Alignment.topCenter,
                            constrainedAxis: Axis.vertical,
                            child: _PlayerResultCard(
                              position: position,
                              player: player,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 12,
                    child: _NavArrow(
                      enabled: _currentPage > 0,
                      icon: Icons.chevron_left,
                      onTap: () => _goToPage(_currentPage - 1, total),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: _NavArrow(
                      enabled: _currentPage < total - 1,
                      icon: Icons.chevron_right,
                      onTap: () => _goToPage(_currentPage + 1, total),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Row(
                      children: List.generate(total, (i) {
                        final active = i == _currentPage;
                        return Container(
                          width: active ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () async {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId != null) {
                  await UserService().setActiveGame(currentUserId, null);
                }
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
                await gameService.deleteGame(widget.gameId);
              },
              child: const Text('Back to Lobby'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerResultCard extends StatelessWidget {
  final int position;
  final Player player;

  const _PlayerResultCard({required this.position, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position == 1
                ? 'Champion'
                : position == 2
                    ? 'Runner-up'
                    : position == 3
                        ? 'Third Place'
                        : '#$position',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: _PlayerImage(imageUrl: player.image),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  player.username,
                  style: theme.textTheme.titleLarge,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${player.score} pts',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
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
        debugPrint('[ResultsScreen] loading image ${imageUrl} loaded=$loaded expected=$expected');
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

class _NavArrow extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.enabled, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.3,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
