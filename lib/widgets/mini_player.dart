import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';
import '../screens/full_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        if (!playerService.hasEpisode) {
          return SizedBox.shrink();
        }

        final episode = playerService.currentEpisode!;
        final podcast = playerService.currentPodcast!;

        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullPlayerScreen(),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Stack(
                  children: [
                    // Episode/Podcast image positioned on the left
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: episode.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: episode.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                  child: Icon(Icons.music_note, color: Colors.grey),
                                ),
                                errorWidget: (context, url, error) => _fallbackImage(podcast),
                              )
                            : _fallbackImage(podcast),
                        ),
                      ),
                    ),
                    // Player controls centered in the full width
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        // Skip backward 10s
                        IconButton(
                          onPressed: playerService.isLoading ? null : () => playerService.skipBackward(),
                          icon: Icon(Icons.replay_10),
                          iconSize: 50,
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                        // Play/Pause
                        IconButton(
                          onPressed: playerService.isLoading ? null : () {
                            if (playerService.isPlaying) {
                              playerService.pause();
                            } else {
                              playerService.play();
                            }
                          },
                          icon: playerService.isLoading || playerService.playerState == PlayerState.buffering
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                playerService.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              ),
                          iconSize: 50,
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(minWidth: 48, minHeight: 48),
                        ),

                        // Skip forward 30s
                        IconButton(
                          onPressed: playerService.isLoading ? null : () => playerService.skipForward(),
                          icon: Icon(Icons.forward_30),
                          iconSize: 50,
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackImage(podcast) {
    return podcast.imageUrl != null
      ? CachedNetworkImage(
          imageUrl: podcast.imageUrl!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 54,
            height: 54,
            color: Colors.grey.shade300,
            child: Icon(Icons.music_note, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            width: 54,
            height: 54,
            color: Colors.grey.shade300,
            child: Icon(Icons.music_note, color: Colors.grey),
          ),
        )
      : Container(
          width: 54,
          height: 54,
          color: Colors.grey.shade300,
          child: Icon(Icons.music_note, color: Colors.grey),
        );
  }
}