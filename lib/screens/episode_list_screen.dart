import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/podcast_image.dart';
import '../database/database_helper.dart';
import 'episode_detail_screen.dart';

class EpisodeListScreen extends StatefulWidget {
  final Podcast podcast;

  const EpisodeListScreen({super.key, required this.podcast});

  @override
  State<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends State<EpisodeListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Podcast _podcast;
  List<Episode> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _podcast = widget.podcast;
    _loadPodcastData();
  }

  Future<void> _loadPodcastData() async {
    final podcast = await _dbHelper.getPodcast(widget.podcast.id!);
    if (podcast != null) {
      final episodes = await _dbHelper.getEpisodesForPodcast(podcast.id!);
      setState(() {
        _podcast = podcast;
        _episodes = episodes;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSortOrder(EpisodeSortOrder newSortOrder) async {
    final updatedPodcast = _podcast.copyWith(sortOrder: newSortOrder);
    await _dbHelper.updatePodcast(updatedPodcast);
    await _loadPodcastData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_podcast.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<EpisodeSortOrder>(
            icon: Icon(Icons.sort),
            onSelected: _updateSortOrder,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: EpisodeSortOrder.newestFirst,
                child: Row(
                  children: [
                    if (_podcast.sortOrder == EpisodeSortOrder.newestFirst)
                      Icon(Icons.check, size: 20)
                    else
                      SizedBox(width: 20),
                    SizedBox(width: 8),
                    Text(EpisodeSortOrder.newestFirst.displayName),
                  ],
                ),
              ),
              PopupMenuItem(
                value: EpisodeSortOrder.oldestFirst,
                child: Row(
                  children: [
                    if (_podcast.sortOrder == EpisodeSortOrder.oldestFirst)
                      Icon(Icons.check, size: 20)
                    else
                      SizedBox(width: 20),
                    SizedBox(width: 8),
                    Text(EpisodeSortOrder.oldestFirst.displayName),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                  imageUrl: _podcast.imageUrl,
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
                        _podcast.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_podcast.author != null) ...[
                        SizedBox(height: 4),
                        Text(
                          _podcast.author!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                      SizedBox(height: 8),
                      Text(
                        '${_episodes.length} episodes',
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
            child: _episodes.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_play, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No episodes available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                  itemCount: _episodes.length,
                  itemBuilder: (context, index) {
                    final episode = _episodes[index];
                    return EpisodeTile(episode: episode, podcast: _podcast);
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

  const EpisodeTile({super.key, required this.episode, required this.podcast});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                episode.formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              if (episode.formattedDuration.isNotEmpty) ...[
                Text(
                  ' • ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  episode.formattedDuration,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          SizedBox(height: 4),
          Text(
            episode.title,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
            onPressed: isLoading
                ? null
                : () {
                    audioService.playEpisode(episode, podcast);
                  },
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EpisodeDetailScreen(episode: episode, podcast: podcast),
          ),
        );
      },
    );
  }
}
