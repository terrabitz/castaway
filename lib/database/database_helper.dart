import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/podcast.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'castaway.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE podcasts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        rss_url TEXT UNIQUE NOT NULL,
        image_url TEXT,
        author TEXT,
        last_fetched INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        podcast_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        audio_url TEXT NOT NULL,
        pub_date INTEGER NOT NULL,
        duration_seconds INTEGER,
        image_url TEXT,
        FOREIGN KEY (podcast_id) REFERENCES podcasts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_episodes_podcast_id ON episodes (podcast_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_episodes_pub_date ON episodes (pub_date DESC)
    ''');
  }


  Future<int> insertPodcast(Podcast podcast) async {
    final db = await database;
    final map = _podcastToMap(podcast);
    final podcastId = await db.insert('podcasts', map);

    // Insert episodes separately
    for (final episode in podcast.episodes) {
      await _insertEpisode(db, podcastId, episode);
    }

    return podcastId;
  }

  Future<List<Podcast>> getAllPodcasts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('podcasts');
    final List<Podcast> podcasts = [];

    for (final map in maps) {
      final episodes = await _getEpisodesForPodcast(db, map['id']);
      podcasts.add(_mapToPodcast(map, episodes));
    }

    return podcasts;
  }

  Future<Podcast?> getPodcastByRssUrl(String rssUrl) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [rssUrl],
    );

    if (maps.isEmpty) return null;
    final episodes = await _getEpisodesForPodcast(db, maps.first['id']);
    return _mapToPodcast(maps.first, episodes);
  }

  Future<int> updatePodcast(Podcast podcast) async {
    final db = await database;
    final map = _podcastToMap(podcast);
    final result = await db.update(
      'podcasts',
      map,
      where: 'id = ?',
      whereArgs: [podcast.id],
    );

    // Update episodes - delete old ones and insert new ones
    await db.delete(
      'episodes',
      where: 'podcast_id = ?',
      whereArgs: [podcast.id],
    );

    for (final episode in podcast.episodes) {
      await _insertEpisode(db, podcast.id!, episode);
    }

    return result;
  }

  Future<int> deletePodcast(int id) async {
    final db = await database;
    // Episodes will be deleted automatically due to CASCADE
    return await db.delete(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePodcastByRssUrl(String rssUrl) async {
    final db = await database;
    // Episodes will be deleted automatically due to CASCADE
    return await db.delete(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [rssUrl],
    );
  }

  Future<void> updatePodcastEpisodes(int podcastId, List<Episode> episodes) async {
    final db = await database;

    // Delete existing episodes
    await db.delete(
      'episodes',
      where: 'podcast_id = ?',
      whereArgs: [podcastId],
    );

    // Insert new episodes
    for (final episode in episodes) {
      await _insertEpisode(db, podcastId, episode);
    }

    // Update last_fetched timestamp
    await db.update(
      'podcasts',
      {'last_fetched': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [podcastId],
    );
  }


  Map<String, dynamic> _podcastToMap(Podcast podcast) {
    return {
      'id': podcast.id,
      'title': podcast.title,
      'description': podcast.description,
      'rss_url': podcast.rssUrl,
      'image_url': podcast.imageUrl,
      'author': podcast.author,
      'last_fetched': podcast.lastFetched?.millisecondsSinceEpoch,
    };
  }

  Podcast _mapToPodcast(Map<String, dynamic> map, List<Episode> episodes) {
    return Podcast(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rssUrl: map['rss_url'] ?? '',
      imageUrl: map['image_url'],
      author: map['author'],
      episodes: episodes,
      lastFetched: map['last_fetched'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_fetched'])
          : null,
    );
  }

  Future<List<Episode>> _getEpisodesForPodcast(Database db, int podcastId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'episodes',
      where: 'podcast_id = ?',
      whereArgs: [podcastId],
      orderBy: 'pub_date DESC',
    );

    return maps.map((map) => _mapToEpisode(map)).toList();
  }

  Future<int> _insertEpisode(Database db, int podcastId, Episode episode) async {
    return await db.insert('episodes', {
      'podcast_id': podcastId,
      'title': episode.title,
      'description': episode.description,
      'audio_url': episode.audioUrl,
      'pub_date': episode.pubDate.millisecondsSinceEpoch,
      'duration_seconds': episode.duration?.inSeconds,
      'image_url': episode.imageUrl,
    });
  }

  Episode _mapToEpisode(Map<String, dynamic> map) {
    return Episode(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      audioUrl: map['audio_url'] ?? '',
      pubDate: DateTime.fromMillisecondsSinceEpoch(map['pub_date'] ?? 0),
      duration: map['duration_seconds'] != null
          ? Duration(seconds: map['duration_seconds'])
          : null,
      imageUrl: map['image_url'],
    );
  }

  Future<List<Episode>> getEpisodesForPodcast(int podcastId) async {
    final db = await database;
    return await _getEpisodesForPodcast(db, podcastId);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}