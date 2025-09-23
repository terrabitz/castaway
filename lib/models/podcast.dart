class Podcast {
  final int? id;
  final String title;
  final String description;
  final String rssUrl;
  final String? imageUrl;
  final String? author;
  final List<Episode> episodes;
  final DateTime? lastFetched;

  Podcast({
    this.id,
    required this.title,
    required this.description,
    required this.rssUrl,
    this.imageUrl,
    this.author,
    this.episodes = const [],
    this.lastFetched,
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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'pubDate': pubDate.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'imageUrl': imageUrl,
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
}