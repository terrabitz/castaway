import 'package:flutter/material.dart';
import '../models/podcast.dart';
import 'podcast_image.dart';

class PodcastTile extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const PodcastTile({
    super.key,
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: PodcastImage(
            imageUrl: podcast.imageUrl,
            fit: BoxFit.cover,
            iconSize: 32,
          ),
        ),
      ),
    );
  }
}