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
        last_fetched INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0
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
    return await db.insert('podcasts', map);
  }

  Future<List<Podcast>> getAllPodcasts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('podcasts');
    return maps.map((map) => _mapToPodcast(map, [])).toList();
  }

  Future<Podcast?> getPodcast(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToPodcast(maps.first, []);
  }

  Future<Podcast?> getPodcastByRssUrl(String rssUrl) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [rssUrl],
    );

    if (maps.isEmpty) return null;
    return _mapToPodcast(maps.first, []);
  }

  Future<int> updatePodcast(Podcast podcast) async {
    final db = await database;
    final map = _podcastToMap(podcast);
    return await db.update(
      'podcasts',
      map,
      where: 'id = ?',
      whereArgs: [podcast.id],
    );
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
      'sort_order': podcast.sortOrder.index,
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
      sortOrder: (() {
        final sortOrderValue = map['sort_order'];
        return sortOrderValue != null
            ? EpisodeSortOrder.values[sortOrderValue is int ? sortOrderValue : int.parse(sortOrderValue.toString())]
            : EpisodeSortOrder.newestFirst;
      })(),
    );
  }

  Future<List<Episode>> _getEpisodesForPodcast(Database db, int podcastId, {EpisodeSortOrder sortOrder = EpisodeSortOrder.newestFirst}) async {
    final orderBy = sortOrder == EpisodeSortOrder.newestFirst
        ? 'pub_date DESC'
        : 'pub_date ASC';

    final List<Map<String, dynamic>> maps = await db.query(
      'episodes',
      where: 'podcast_id = ?',
      whereArgs: [podcastId],
      orderBy: orderBy,
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
    final podcast = await getPodcast(podcastId);
    if (podcast == null) return [];

    final sortOrder = podcast.sortOrder;
    return await _getEpisodesForPodcast(db, podcastId, sortOrder: sortOrder);
  }

  Future<Episode?> getEpisode(int podcastId, String audioUrl) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'episodes',
      where: 'podcast_id = ? AND audio_url = ?',
      whereArgs: [podcastId, audioUrl],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToEpisode(maps.first);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}