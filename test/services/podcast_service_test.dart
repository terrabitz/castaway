import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:castaway/services/podcast_service.dart';

void main() {
  group('PodcastService RSS Parsing Tests', () {
    late String sampleRssXml;

    setUp(() async {
      final file = File('test/fixtures/sample_rss.xml');
      sampleRssXml = await file.readAsString();
    });

    test('should parse complete RSS feed correctly', () {
      final podcast = PodcastService.parseRss(sampleRssXml, 'https://example.com/feed.xml');

      expect(podcast.title, equals('Test Podcast'));
      expect(podcast.description, equals('A test podcast for unit testing'));
      expect(podcast.author, equals('Test Author'));
      expect(podcast.imageUrl, equals('https://example.com/podcast-image.jpg'));
      expect(podcast.rssUrl, equals('https://example.com/feed.xml'));
      expect(podcast.episodes.length, equals(4));

      final ep1 = podcast.episodes.firstWhere((e) => e.title == 'Episode 1: Introduction');
      expect(ep1.description, equals('This is the first episode of our test podcast'));
      expect(ep1.audioUrl, equals('https://example.com/episode1.mp3'));
      expect(ep1.imageUrl, equals('https://example.com/episode1-image.jpg'));
      expect(ep1.pubDate.year, equals(2025));
      expect(ep1.pubDate.month, equals(9));
      expect(ep1.pubDate.day, equals(22));
      expect(ep1.duration!.inSeconds, equals(2730));

      final ep2 = podcast.episodes.firstWhere((e) => e.title == 'Episode 2: Advanced Topics');
      expect(ep2.imageUrl, equals('https://example.com/podcast-image.jpg'));
      expect(ep2.duration!.inSeconds, equals(4365));

      final ep3 = podcast.episodes.firstWhere((e) => e.title == 'Episode 3: No Duration');
      expect(ep3.duration, isNull);

      final ep4 = podcast.episodes.firstWhere((e) => e.title == 'Episode 4: Invalid Date');
      expect(ep4.pubDate, isNotNull);
    });
  });
}