import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Now Playing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, child) {
          if (!playerService.hasEpisode) {
            return Center(
              child: Text('No episode playing'),
            );
          }

          final episode = playerService.currentEpisode!;
          final podcast = playerService.currentPodcast!;

          return Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Large episode artwork
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: episode.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: episode.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade300,
                                child: Icon(Icons.music_note, size: 80, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => _fallbackImage(podcast),
                            )
                          : _fallbackImage(podcast),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Episode info
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        episode.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        podcast.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Progress slider
                Column(
                  children: [
                    Slider(
                      value: playerService.progress.clamp(0.0, 1.0),
                      onChanged: playerService.isLoading ? null : (value) {
                        final position = Duration(
                          milliseconds: (value * playerService.duration.inMilliseconds).round(),
                        );
                        playerService.seekTo(position);
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            playerService.formattedPosition,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            playerService.formattedDuration,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Player controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous episode
                    IconButton(
                      onPressed: playerService.isLoading ? null : () => playerService.previousEpisode(),
                      icon: Icon(Icons.skip_previous),
                      iconSize: 40,
                    ),

                    // Skip backward 10s
                    IconButton(
                      onPressed: playerService.isLoading ? null : () => playerService.skipBackward(),
                      icon: Icon(Icons.replay_10),
                      iconSize: 40,
                    ),

                    // Play/Pause (large)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: IconButton(
                        onPressed: playerService.isLoading ? null : () {
                          if (playerService.isPlaying) {
                            playerService.pause();
                          } else {
                            playerService.play();
                          }
                        },
                        icon: playerService.isLoading || playerService.playerState == PlayerState.buffering
                          ? SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              playerService.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                        iconSize: 48,
                        padding: EdgeInsets.all(16),
                      ),
                    ),

                    // Skip forward 30s
                    IconButton(
                      onPressed: playerService.isLoading ? null : () => playerService.skipForward(),
                      icon: Icon(Icons.forward_30),
                      iconSize: 40,
                    ),

                    // Next episode
                    IconButton(
                      onPressed: playerService.isLoading ? null : () => playerService.nextEpisode(),
                      icon: Icon(Icons.skip_next),
                      iconSize: 40,
                    ),
                  ],
                ),

                SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackImage(podcast) {
    return podcast.imageUrl != null
      ? CachedNetworkImage(
          imageUrl: podcast.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade300,
            child: Icon(Icons.music_note, size: 80, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade300,
            child: Icon(Icons.music_note, size: 80, color: Colors.grey),
          ),
        )
      : Container(
          color: Colors.grey.shade300,
          child: Icon(Icons.music_note, size: 80, color: Colors.grey),
        );
  }
}