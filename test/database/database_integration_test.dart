import 'package:flutter_test/flutter_test.dart';
import 'package:castaway/database/database_helper.dart';
import 'package:castaway/models/podcast.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Integration Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      await db.delete('podcasts');
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('should insert podcast with episodes and retrieve correctly', () async {
      final podcast = Podcast(
        title: 'Test Podcast',
        description: 'A test podcast for database testing',
        rssUrl: 'https://example.com/feed.xml',
        imageUrl: 'https://example.com/image.jpg',
        author: 'Test Author',
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'First episode',
            audioUrl: 'https://example.com/ep1.mp3',
            pubDate: DateTime(2025, 9, 22, 14, 0, 0),
            duration: Duration(minutes: 45, seconds: 30),
            imageUrl: 'https://example.com/ep1.jpg',
          ),
          Episode(
            title: 'Episode 2',
            description: 'Second episode',
            audioUrl: 'https://example.com/ep2.mp3',
            pubDate: DateTime(2025, 9, 24, 10, 30, 0),
            duration: Duration(hours: 1, minutes: 12, seconds: 45),
            imageUrl: null,
          ),
        ],
        lastFetched: DateTime.now(),
      );

      final podcastId = await dbHelper.insertPodcast(podcast);
      expect(podcastId, isNotNull);
      expect(podcastId, greaterThan(0));

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(podcastId));
      expect(retrieved.title, equals('Test Podcast'));
      expect(retrieved.description, equals('A test podcast for database testing'));
      expect(retrieved.rssUrl, equals('https://example.com/feed.xml'));
      expect(retrieved.author, equals('Test Author'));
      expect(retrieved.episodes.length, equals(2));

      final ep1 = retrieved.episodes.firstWhere((e) => e.title == 'Episode 1');
      expect(ep1.description, equals('First episode'));
      expect(ep1.audioUrl, equals('https://example.com/ep1.mp3'));
      expect(ep1.pubDate.year, equals(2025));
      expect(ep1.pubDate.month, equals(9));
      expect(ep1.pubDate.day, equals(22));
      expect(ep1.duration!.inSeconds, equals(2730));
      expect(ep1.imageUrl, equals('https://example.com/ep1.jpg'));

      final ep2 = retrieved.episodes.firstWhere((e) => e.title == 'Episode 2');
      expect(ep2.imageUrl, isNull);
      expect(ep2.duration!.inSeconds, equals(4365));
    });

    test('should update podcast and preserve episodes', () async {
      final podcast = Podcast(
        title: 'Original Title',
        description: 'Original description',
        rssUrl: 'https://example.com/feed2.xml',
        imageUrl: null,
        author: 'Original Author',
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'First episode',
            audioUrl: 'https://example.com/ep1.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
        ],
        lastFetched: DateTime.now(),
      );

      final podcastId = await dbHelper.insertPodcast(podcast);

      final updatedPodcast = podcast.copyWith(
        id: podcastId,
        title: 'Updated Title',
        description: 'Updated description',
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'First episode',
            audioUrl: 'https://example.com/ep1.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
          Episode(
            title: 'Episode 2',
            description: 'New episode',
            audioUrl: 'https://example.com/ep2.mp3',
            pubDate: DateTime.now(),
            duration: Duration(minutes: 30),
            imageUrl: null,
          ),
        ],
      );

      await dbHelper.updatePodcast(updatedPodcast);

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved!.title, equals('Updated Title'));
      expect(retrieved.description, equals('Updated description'));
      expect(retrieved.episodes.length, equals(2));
    });

    test('should delete podcast and cascade delete episodes', () async {
      final podcast = Podcast(
        title: 'Podcast to Delete',
        description: 'Will be deleted',
        rssUrl: 'https://example.com/delete.xml',
        imageUrl: null,
        author: null,
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'Episode',
            audioUrl: 'https://example.com/ep.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
        ],
        lastFetched: DateTime.now(),
      );

      final podcastId = await dbHelper.insertPodcast(podcast);

      var retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);
      expect(retrieved!.episodes.length, equals(1));

      await dbHelper.deletePodcast(podcastId);

      retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNull);
    });

    test('should retrieve all podcasts with episodes', () async {
      final podcast1 = Podcast(
        title: 'Podcast 1',
        description: 'First podcast',
        rssUrl: 'https://example.com/feed1.xml',
        imageUrl: null,
        author: null,
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'Episode',
            audioUrl: 'https://example.com/ep1.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
        ],
        lastFetched: DateTime.now(),
      );

      final podcast2 = Podcast(
        title: 'Podcast 2',
        description: 'Second podcast',
        rssUrl: 'https://example.com/feed2.xml',
        imageUrl: null,
        author: null,
        episodes: [
          Episode(
            title: 'Episode 1',
            description: 'Episode',
            audioUrl: 'https://example.com/ep1.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
          Episode(
            title: 'Episode 2',
            description: 'Episode',
            audioUrl: 'https://example.com/ep2.mp3',
            pubDate: DateTime.now(),
            duration: null,
            imageUrl: null,
          ),
        ],
        lastFetched: DateTime.now(),
      );

      await dbHelper.insertPodcast(podcast1);
      await dbHelper.insertPodcast(podcast2);

      final allPodcasts = await dbHelper.getAllPodcasts();
      expect(allPodcasts.length, greaterThanOrEqualTo(2));

      final retrievedPodcast1 = allPodcasts.firstWhere((p) => p.title == 'Podcast 1');
      final retrievedPodcast2 = allPodcasts.firstWhere((p) => p.title == 'Podcast 2');

      expect(retrievedPodcast1.episodes.length, equals(1));
      expect(retrievedPodcast2.episodes.length, equals(2));
    });

    test('should retrieve podcast by RSS URL', () async {
      final podcast = Podcast(
        title: 'URL Test Podcast',
        description: 'Testing URL retrieval',
        rssUrl: 'https://example.com/unique-feed.xml',
        imageUrl: null,
        author: null,
        episodes: [],
        lastFetched: DateTime.now(),
      );

      await dbHelper.insertPodcast(podcast);

      final retrieved = await dbHelper.getPodcastByRssUrl('https://example.com/unique-feed.xml');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('URL Test Podcast'));

      final notFound = await dbHelper.getPodcastByRssUrl('https://example.com/nonexistent.xml');
      expect(notFound, isNull);
    });

    test('should enforce unique RSS URL constraint', () async {
      final podcast1 = Podcast(
        title: 'First Podcast',
        description: 'First',
        rssUrl: 'https://example.com/same-feed.xml',
        imageUrl: null,
        author: null,
        episodes: [],
        lastFetched: DateTime.now(),
      );

      final podcast2 = Podcast(
        title: 'Second Podcast',
        description: 'Second',
        rssUrl: 'https://example.com/same-feed.xml',
        imageUrl: null,
        author: null,
        episodes: [],
        lastFetched: DateTime.now(),
      );

      await dbHelper.insertPodcast(podcast1);

      expect(
        () async => await dbHelper.insertPodcast(podcast2),
        throwsException,
      );
    });
  });
}