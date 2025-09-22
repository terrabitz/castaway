class Podcast {
  final String title;
  final String description;
  final String rssUrl;
  final String? imageUrl;
  final String? author;
  final List<Episode> episodes;

  Podcast({
    required this.title,
    required this.description,
    required this.rssUrl,
    this.imageUrl,
    this.author,
    this.episodes = const [],
  });

  Podcast copyWith({
    String? title,
    String? description,
    String? rssUrl,
    String? imageUrl,
    String? author,
    List<Episode>? episodes,
  }) {
    return Podcast(
      title: title ?? this.title,
      description: description ?? this.description,
      rssUrl: rssUrl ?? this.rssUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      episodes: episodes ?? this.episodes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Podcast && other.rssUrl == rssUrl;
  }

  @override
  int get hashCode => rssUrl.hashCode;
}

class Episode {
  final String title;
  final String description;
  final String audioUrl;
  final DateTime pubDate;
  final Duration? duration;
  final String? imageUrl;

  Episode({
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.pubDate,
    this.duration,
    this.imageUrl,
  });

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedDate {
    return '${pubDate.day}/${pubDate.month}/${pubDate.year}';
  }
}