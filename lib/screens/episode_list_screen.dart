import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
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
  bool _isDescriptionExpanded = false;
  bool _showReadMore = false;
  final GlobalKey _descriptionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _podcast = widget.podcast;
    _loadPodcastData();
  }

  Future<void> _loadPodcastData() async {
    _checkDescriptionOverflow();
    
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

  void _checkDescriptionOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _descriptionKey.currentContext;
      if (context != null && mounted) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final maxHeight = 72.0;
          final actualHeight = renderBox.size.height;
          if (actualHeight > maxHeight && !_showReadMore) {
            setState(() {
              _showReadMore = true;
            });
          }
        }
      }
    });
  }

  void _updateSortOrder(EpisodeSortOrder newSortOrder) async {
    final updatedPodcast = _podcast.copyWith(sortOrder: newSortOrder);
    await _dbHelper.updatePodcast(updatedPodcast);
    await _loadPodcastData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: false,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 24),
                      Center(
                        child: PodcastImage(
                          imageUrl: _podcast.imageUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          iconSize: 80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              _podcast.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_podcast.author != null) ...[
                              SizedBox(height: 8),
                              Text(
                                _podcast.author!,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (_podcast.description.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Column(
                                children: [
                                  Stack(
                                    children: [
                                      ClipRect(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxHeight: _isDescriptionExpanded ? double.infinity : 72,
                                          ),
                                          child: SingleChildScrollView(
                                            physics: NeverScrollableScrollPhysics(),
                                            child: Html(
                                              key: _descriptionKey,
                                              data: _podcast.description,
                                              style: {
                                                "body": Style(
                                                  margin: Margins.zero,
                                                  padding: HtmlPaddings.zero,
                                                  textAlign: TextAlign.justify,
                                                  color: Colors.grey.shade700,
                                                  fontSize: FontSize(Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14),
                                                ),
                                                "p": Style(
                                                  margin: Margins.only(bottom: 4),
                                                  textAlign: TextAlign.justify,
                                                ),
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_showReadMore && !_isDescriptionExpanded)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: 24,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Theme.of(context).scaffoldBackgroundColor,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (_showReadMore)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isDescriptionExpanded = !_isDescriptionExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isDescriptionExpanded ? 'Read less' : 'Read more',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
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
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Episodes',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            PopupMenuButton<EpisodeSortOrder>(
                              icon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _podcast.sortOrder.displayName,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
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
                      ),
                      Divider(),
                    ],
                  ),
                ),
                _episodes.isEmpty && !_isLoading
                    ? SliverFillRemaining(
                        child: Center(
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
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final episode = _episodes[index];
                            return EpisodeTile(episode: episode, podcast: _podcast);
                          },
                          childCount: _episodes.length,
                        ),
                      ),
              ],
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
