import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/podcast.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/podcast_image.dart';

class EpisodeDetailScreen extends StatelessWidget {
  final Episode episode;
  final Podcast podcast;

  const EpisodeDetailScreen({
    super.key,
    required this.episode,
    required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Episode Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AudioPlayerService>(
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
                          Theme.of(context).colorScheme.onSurface,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Episode image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PodcastImage(
                  imageUrl: episode.imageUrl ?? podcast.imageUrl,
                  width: 100,
                  height: 100,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        episode.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (episode.formattedDuration.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          episode.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Episode title
            Text(
              episode.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Play button
            Consumer<AudioPlayerService>(
              builder: (context, audioService, child) {
                final isCurrentEpisode = audioService.currentEpisode == episode;
                final isLoading = isCurrentEpisode && audioService.isLoading;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () {
                      audioService.playEpisode(episode, podcast);
                    },
                    icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(Icons.play_arrow),
                    label: Text(isLoading ? 'Loading...' : 'Play Episode'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),

            // Episode description with HTML rendering
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Html(
              data: episode.description,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 8),
                ),
                "a": Style(
                  color: Theme.of(context).colorScheme.primary,
                  textDecoration: TextDecoration.underline,
                ),
              },
              onLinkTap: (url, _, __) {
                // Handle link taps - could open in browser
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link: $url'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: MiniPlayer(),
    );
  }
}