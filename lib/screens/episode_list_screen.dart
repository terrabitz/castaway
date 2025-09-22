import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/podcast_image.dart';
import 'episode_detail_screen.dart';

class EpisodeListScreen extends StatelessWidget {
  final Podcast podcast;

  const EpisodeListScreen({
    super.key,
    required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(podcast.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Podcast header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PodcastImage(
                  imageUrl: podcast.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  iconSize: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (podcast.author != null) ...[
                        SizedBox(height: 4),
                        Text(
                          podcast.author!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Text(
                        '${podcast.episodes.length} episodes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          // Episodes list
          Expanded(
            child: podcast.episodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No episodes available',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: podcast.episodes.length,
                  itemBuilder: (context, index) {
                    final episode = podcast.episodes[index];
                    return EpisodeTile(
                      episode: episode,
                      podcast: podcast,
                    );
                  },
                ),
          ),
        ],
      ),
      bottomNavigationBar: MiniPlayer(),
    );
  }
}

class EpisodeTile extends StatelessWidget {
  final Episode episode;
  final Podcast podcast;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: PodcastImage(
          imageUrl: episode.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          iconSize: 24,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          episode.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              episode.formattedDate,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            if (episode.formattedDuration.isNotEmpty) ...[
              Text(
                ' • ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                episode.formattedDuration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        trailing: Consumer<AudioPlayerService>(
          builder: (context, audioService, child) {
            final isCurrentEpisode = audioService.currentEpisode == episode;
            final isLoading = isCurrentEpisode && audioService.isLoading;

            return IconButton(
              icon: isLoading
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
                : Icon(Icons.play_arrow),
              onPressed: isLoading ? null : () {
                audioService.playEpisode(episode, podcast);
              },
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EpisodeDetailScreen(
                episode: episode,
                podcast: podcast,
              ),
            ),
          );
        },
      ),
    );
  }
}