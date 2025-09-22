import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/podcast.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

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
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              final audioService = Provider.of<AudioPlayerService>(context, listen: false);
              audioService.playEpisode(episode, podcast);
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: episode.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: episode.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.play_circle_outline, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.play_circle_outline, color: Colors.grey),
                        ),
                      )
                    : podcast.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: podcast.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.play_circle_outline, color: Colors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.play_circle_outline, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.play_circle_outline, color: Colors.grey),
                        ),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final audioService = Provider.of<AudioPlayerService>(context, listen: false);
                  audioService.playEpisode(episode, podcast);
                },
                icon: Icon(Icons.play_arrow),
                label: Text('Play Episode'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
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