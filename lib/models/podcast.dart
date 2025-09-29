enum EpisodeSortOrder {
  newestFirst,
  oldestFirst;

  String get displayName {
    switch (this) {
      case EpisodeSortOrder.newestFirst:
        return 'Newest to Oldest';
      case EpisodeSortOrder.oldestFirst:
        return 'Oldest to Newest';
    }
  }
}

class Podcast {
  final int? id;
  final String title;
  final String description;
  final String rssUrl;
  final String? imageUrl;
  final String? author;
  final List<Episode> episodes;
  final DateTime? lastFetched;
  final EpisodeSortOrder sortOrder;

  Podcast({
    this.id,
    required this.title,
    required this.description,
    required this.rssUrl,
    this.imageUrl,
    this.author,
    this.episodes = const [],
    this.lastFetched,
    this.sortOrder = EpisodeSortOrder.newestFirst,
  });

  Podcast copyWith({
    int? id,
    String? title,
    String? description,
    String? rssUrl,
    String? imageUrl,
    String? author,
    List<Episode>? episodes,
    DateTime? lastFetched,
    EpisodeSortOrder? sortOrder,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rssUrl: rssUrl ?? this.rssUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      episodes: episodes ?? this.episodes,
      lastFetched: lastFetched ?? this.lastFetched,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rssUrl': rssUrl,
      'imageUrl': imageUrl,
      'author': author,
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'lastFetched': lastFetched?.millisecondsSinceEpoch,
      'sortOrder': sortOrder.index,
    };
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rssUrl: json['rssUrl'] ?? '',
      imageUrl: json['imageUrl'],
      author: json['author'],
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastFetched: json['lastFetched'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastFetched'])
          : null,
      sortOrder: json['sortOrder'] != null
          ? EpisodeSortOrder.values[json['sortOrder']]
          : EpisodeSortOrder.newestFirst,
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
  final int progressSeconds;
  final DateTime? finishedAt;

  Episode({
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.pubDate,
    this.duration,
    this.imageUrl,
    this.progressSeconds = 0,
    this.finishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'pubDate': pubDate.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'imageUrl': imageUrl,
      'progressSeconds': progressSeconds,
      'finishedAt': finishedAt?.millisecondsSinceEpoch,
    };
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      pubDate: DateTime.fromMillisecondsSinceEpoch(json['pubDate'] ?? 0),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      imageUrl: json['imageUrl'],
      progressSeconds: json['progressSeconds'] ?? 0,
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finishedAt'])
          : null,
    );
  }

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
    final year = pubDate.year.toString();
    final month = pubDate.month.toString().padLeft(2, '0');
    final day = pubDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool get isFinished => finishedAt != null;

  double get progressPercentage {
    if (duration == null || duration!.inSeconds == 0) return 0.0;
    return (progressSeconds / duration!.inSeconds).clamp(0.0, 1.0);
  }

  String get formattedProgress {
    final hours = progressSeconds ~/ 3600;
    final minutes = (progressSeconds % 3600) ~/ 60;
    final seconds = progressSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Episode copyWith({
    String? title,
    String? description,
    String? audioUrl,
    DateTime? pubDate,
    Duration? duration,
    String? imageUrl,
    int? progressSeconds,
    DateTime? finishedAt,
  }) {
    return Episode(
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      pubDate: pubDate ?? this.pubDate,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}