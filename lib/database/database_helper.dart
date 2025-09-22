import 'dart:convert';
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
      version: 1,
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
        episodes_json TEXT NOT NULL,
        last_fetched INTEGER
      )
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
    return maps.map((map) => _mapToPodcast(map)).toList();
  }

  Future<Podcast?> getPodcastByRssUrl(String rssUrl) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [rssUrl],
    );

    if (maps.isEmpty) return null;
    return _mapToPodcast(maps.first);
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
    return await db.delete(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePodcastByRssUrl(String rssUrl) async {
    final db = await database;
    return await db.delete(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [rssUrl],
    );
  }

  Future<void> updatePodcastEpisodes(int podcastId, List<Episode> episodes) async {
    final db = await database;
    final episodesJson = jsonEncode(episodes.map((e) => e.toJson()).toList());

    await db.update(
      'podcasts',
      {
        'episodes_json': episodesJson,
        'last_fetched': DateTime.now().millisecondsSinceEpoch,
      },
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
      'episodes_json': jsonEncode(podcast.episodes.map((e) => e.toJson()).toList()),
      'last_fetched': podcast.lastFetched?.millisecondsSinceEpoch,
    };
  }

  Podcast _mapToPodcast(Map<String, dynamic> map) {
    final episodesJson = map['episodes_json'] as String? ?? '[]';
    final episodesList = jsonDecode(episodesJson) as List<dynamic>;
    final episodes = episodesList
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();

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

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}