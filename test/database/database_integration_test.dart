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
        lastFetched: DateTime.now(),
      );

      final episodes = [
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
      ];

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, episodes);

      expect(podcastId, isNotNull);
      expect(podcastId, greaterThan(0));

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(podcastId));
      expect(retrieved.title, equals('Test Podcast'));
      expect(retrieved.description, equals('A test podcast for database testing'));
      expect(retrieved.rssUrl, equals('https://example.com/feed.xml'));
      expect(retrieved.author, equals('Test Author'));

      final retrievedEpisodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(retrievedEpisodes.length, equals(2));

      final ep1 = retrievedEpisodes.firstWhere((e) => e.title == 'Episode 1');
      expect(ep1.description, equals('First episode'));
      expect(ep1.audioUrl, equals('https://example.com/ep1.mp3'));
      expect(ep1.pubDate.year, equals(2025));
      expect(ep1.pubDate.month, equals(9));
      expect(ep1.pubDate.day, equals(22));
      expect(ep1.duration!.inSeconds, equals(2730));
      expect(ep1.imageUrl, equals('https://example.com/ep1.jpg'));

      final ep2 = retrievedEpisodes.firstWhere((e) => e.title == 'Episode 2');
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
        lastFetched: DateTime.now(),
      );

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, [
        Episode(
          title: 'Episode 1',
          description: 'First episode',
          audioUrl: 'https://example.com/ep1.mp3',
          pubDate: DateTime.now(),
          duration: null,
          imageUrl: null,
        ),
      ]);

      final updatedPodcast = podcast.copyWith(
        id: podcastId,
        title: 'Updated Title',
        description: 'Updated description',
      );

      await dbHelper.updatePodcast(updatedPodcast);
      await dbHelper.updatePodcastEpisodes(podcastId, [
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
      ]);

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved!.title, equals('Updated Title'));
      expect(retrieved.description, equals('Updated description'));

      final episodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(episodes.length, equals(2));
    });

    test('should delete podcast and cascade delete episodes', () async {
      final podcast = Podcast(
        title: 'Podcast to Delete',
        description: 'Will be deleted',
        rssUrl: 'https://example.com/delete.xml',
        imageUrl: null,
        author: null,
        lastFetched: DateTime.now(),
      );

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, [
        Episode(
          title: 'Episode 1',
          description: 'Episode',
          audioUrl: 'https://example.com/ep.mp3',
          pubDate: DateTime.now(),
          duration: null,
          imageUrl: null,
        ),
      ]);

      var retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);

      var episodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(episodes.length, equals(1));

      await dbHelper.deletePodcast(podcastId);

      retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNull);

      episodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(episodes.length, equals(0));
    });

    test('should retrieve all podcasts', () async {
      final podcast1 = Podcast(
        title: 'Podcast 1',
        description: 'First podcast',
        rssUrl: 'https://example.com/feed1.xml',
        imageUrl: null,
        author: null,
        lastFetched: DateTime.now(),
      );

      final podcast2 = Podcast(
        title: 'Podcast 2',
        description: 'Second podcast',
        rssUrl: 'https://example.com/feed2b.xml',
        imageUrl: null,
        author: null,
        lastFetched: DateTime.now(),
      );

      final id1 = await dbHelper.insertPodcast(podcast1);
      final id2 = await dbHelper.insertPodcast(podcast2);

      await dbHelper.updatePodcastEpisodes(id1, [
        Episode(
          title: 'Episode 1',
          description: 'Episode',
          audioUrl: 'https://example.com/ep1.mp3',
          pubDate: DateTime.now(),
          duration: null,
          imageUrl: null,
        ),
      ]);

      await dbHelper.updatePodcastEpisodes(id2, [
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
      ]);

      final allPodcasts = await dbHelper.getAllPodcasts();
      expect(allPodcasts.length, greaterThanOrEqualTo(2));

      final retrievedPodcast1 = allPodcasts.firstWhere((p) => p.title == 'Podcast 1');
      final retrievedPodcast2 = allPodcasts.firstWhere((p) => p.title == 'Podcast 2');

      final episodes1 = await dbHelper.getEpisodesForPodcast(retrievedPodcast1.id!);
      final episodes2 = await dbHelper.getEpisodesForPodcast(retrievedPodcast2.id!);

      expect(episodes1.length, equals(1));
      expect(episodes2.length, equals(2));
    });

    test('should retrieve podcast by RSS URL', () async {
      final podcast = Podcast(
        title: 'URL Test Podcast',
        description: 'Testing URL retrieval',
        rssUrl: 'https://example.com/unique-feed.xml',
        imageUrl: null,
        author: null,
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
        lastFetched: DateTime.now(),
      );

      final podcast2 = Podcast(
        title: 'Second Podcast',
        description: 'Second',
        rssUrl: 'https://example.com/same-feed.xml',
        imageUrl: null,
        author: null,
        lastFetched: DateTime.now(),
      );

      await dbHelper.insertPodcast(podcast1);

      expect(
        () async => await dbHelper.insertPodcast(podcast2),
        throwsException,
      );
    });

    test('should default to newest first sort order', () async {
      final podcast = Podcast(
        title: 'Sort Order Test',
        description: 'Testing default sort order',
        rssUrl: 'https://example.com/sort-test.xml',
      );

      final episodes = [
        Episode(
          title: 'Episode 1',
          description: 'Oldest episode',
          audioUrl: 'https://example.com/ep1.mp3',
          pubDate: DateTime(2025, 9, 20),
        ),
        Episode(
          title: 'Episode 2',
          description: 'Newest episode',
          audioUrl: 'https://example.com/ep2.mp3',
          pubDate: DateTime(2025, 9, 23),
        ),
        Episode(
          title: 'Episode 3',
          description: 'Middle episode',
          audioUrl: 'https://example.com/ep3.mp3',
          pubDate: DateTime(2025, 9, 21),
        ),
      ];

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, episodes);

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);
      expect(retrieved!.sortOrder, equals(EpisodeSortOrder.newestFirst));

      final retrievedEpisodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(retrievedEpisodes.length, equals(3));
      expect(retrievedEpisodes[0].title, equals('Episode 2'));
      expect(retrievedEpisodes[1].title, equals('Episode 3'));
      expect(retrievedEpisodes[2].title, equals('Episode 1'));
    });

    test('should sort episodes oldest first when configured', () async {
      final podcast = Podcast(
        title: 'Oldest First Test',
        description: 'Testing oldest first sort order',
        rssUrl: 'https://example.com/oldest-first.xml',
        sortOrder: EpisodeSortOrder.oldestFirst,
      );

      final episodes = [
        Episode(
          title: 'Episode 1',
          description: 'Oldest episode',
          audioUrl: 'https://example.com/ep1.mp3',
          pubDate: DateTime(2025, 9, 20),
        ),
        Episode(
          title: 'Episode 2',
          description: 'Newest episode',
          audioUrl: 'https://example.com/ep2.mp3',
          pubDate: DateTime(2025, 9, 23),
        ),
        Episode(
          title: 'Episode 3',
          description: 'Middle episode',
          audioUrl: 'https://example.com/ep3.mp3',
          pubDate: DateTime(2025, 9, 21),
        ),
      ];

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, episodes);

      final retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved, isNotNull);
      expect(retrieved!.sortOrder, equals(EpisodeSortOrder.oldestFirst));

      final retrievedEpisodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(retrievedEpisodes.length, equals(3));
      expect(retrievedEpisodes[0].title, equals('Episode 1'));
      expect(retrievedEpisodes[1].title, equals('Episode 3'));
      expect(retrievedEpisodes[2].title, equals('Episode 2'));
    });

    test('should update podcast sort order', () async {
      final podcast = Podcast(
        title: 'Update Sort Order Test',
        description: 'Testing sort order updates',
        rssUrl: 'https://example.com/update-sort.xml',
      );

      final episodes = [
        Episode(
          title: 'Episode 1',
          description: 'Oldest episode',
          audioUrl: 'https://example.com/ep1.mp3',
          pubDate: DateTime(2025, 9, 20),
        ),
        Episode(
          title: 'Episode 2',
          description: 'Newest episode',
          audioUrl: 'https://example.com/ep2.mp3',
          pubDate: DateTime(2025, 9, 23),
        ),
      ];

      final podcastId = await dbHelper.insertPodcast(podcast);
      await dbHelper.updatePodcastEpisodes(podcastId, episodes);

      var retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved!.sortOrder, equals(EpisodeSortOrder.newestFirst));

      var retrievedEpisodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(retrievedEpisodes[0].title, equals('Episode 2'));

      final updatedPodcast = retrieved.copyWith(
        sortOrder: EpisodeSortOrder.oldestFirst,
      );
      await dbHelper.updatePodcast(updatedPodcast);

      retrieved = await dbHelper.getPodcast(podcastId);
      expect(retrieved!.sortOrder, equals(EpisodeSortOrder.oldestFirst));

      retrievedEpisodes = await dbHelper.getEpisodesForPodcast(podcastId);
      expect(retrievedEpisodes[0].title, equals('Episode 1'));
    });
  });
}