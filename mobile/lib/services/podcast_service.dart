import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/podcast.dart';
import '../database/database_helper.dart';

class PodcastService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  static Future<Podcast> fetchPodcast(String rssUrl) async {
    try {
      final response = await http.get(Uri.parse(rssUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final channel = document.findAllElements('channel').first;

      final title = _getElementText(channel, 'title') ?? 'Unknown Podcast';
      final description = _getElementText(channel, 'description') ?? '';
      final imageUrl = _extractImageUrl(channel);
      final author = _getElementText(channel, 'itunes:author') ??
                    _getElementText(channel, 'managingEditor');

      final episodes = <Episode>[];
      final items = channel.findAllElements('item');

      for (final item in items) {
        final episode = _parseEpisode(item, imageUrl);
        if (episode != null) {
          episodes.add(episode);
        }
      }

      final podcast = Podcast(
        title: title,
        description: description,
        rssUrl: rssUrl,
        imageUrl: imageUrl,
        author: author,
        episodes: episodes,
        lastFetched: DateTime.now(),
      );

      // Update database if this is an existing subscription
      final existing = await _dbHelper.getPodcastByRssUrl(rssUrl);
      if (existing != null) {
        final updatedPodcast = podcast.copyWith(id: existing.id);
        await _dbHelper.updatePodcast(updatedPodcast);
        return updatedPodcast;
      }

      return podcast;
    } catch (e) {
      throw Exception('Error parsing RSS feed: $e');
    }
  }

  static Future<Podcast> addPodcastSubscription(String rssUrl) async {
    final podcast = await fetchPodcast(rssUrl);
    final id = await _dbHelper.insertPodcast(podcast);
    return podcast.copyWith(id: id);
  }

  static Future<List<Podcast>> getAllSubscriptions() async {
    return await _dbHelper.getAllPodcasts();
  }

  static Future<void> removePodcastSubscription(Podcast podcast) async {
    if (podcast.id != null) {
      await _dbHelper.deletePodcast(podcast.id!);
    } else {
      await _dbHelper.deletePodcastByRssUrl(podcast.rssUrl);
    }
  }

  static Future<Podcast> refreshPodcast(Podcast podcast) async {
    return await fetchPodcast(podcast.rssUrl);
  }

  static Episode? _parseEpisode(XmlElement item, String? fallbackImageUrl) {
    try {
      final title = _getElementText(item, 'title') ?? 'Unknown Episode';
      final description = _getElementText(item, 'description') ??
                         _getElementText(item, 'itunes:summary') ?? '';
      final audioUrl = _extractAudioUrl(item);
      final pubDateStr = _getElementText(item, 'pubDate');
      final durationStr = _getElementText(item, 'itunes:duration');
      final episodeImageUrl = _extractImageUrl(item) ?? fallbackImageUrl;

      if (audioUrl == null) return null;

      final pubDate = _parsePubDate(pubDateStr) ?? DateTime.now();
      final duration = _parseDuration(durationStr);

      return Episode(
        title: title,
        description: description,
        audioUrl: audioUrl,
        pubDate: pubDate,
        duration: duration,
        imageUrl: episodeImageUrl,
      );
    } catch (e) {
      return null;
    }
  }

  static String? _getElementText(XmlElement parent, String tagName) {
    try {
      return parent.findElements(tagName).first.innerText.trim();
    } catch (e) {
      return null;
    }
  }

  static String? _extractImageUrl(XmlElement element) {
    // Try iTunes image first
    var imageElement = element.findElements('itunes:image').firstOrNull;
    if (imageElement != null) {
      return imageElement.getAttribute('href');
    }

    // Try regular image tag
    imageElement = element.findElements('image').firstOrNull;
    if (imageElement != null) {
      final urlElement = imageElement.findElements('url').firstOrNull;
      if (urlElement != null) {
        return urlElement.innerText.trim();
      }
    }

    return null;
  }

  static String? _extractAudioUrl(XmlElement item) {
    final enclosures = item.findElements('enclosure');
    for (final enclosure in enclosures) {
      final type = enclosure.getAttribute('type');
      if (type != null && type.startsWith('audio/')) {
        return enclosure.getAttribute('url');
      }
    }
    return null;
  }

  static DateTime? _parsePubDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try RFC 2822 format (common in RSS)
        return DateTime.tryParse(dateStr.replaceAll(RegExp(r'\s+\w{3}$'), ''));
      } catch (e) {
        return null;
      }
    }
  }

  static Duration? _parseDuration(String? durationStr) {
    if (durationStr == null) return null;
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        // MM:SS format
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return Duration(minutes: minutes, seconds: seconds);
      } else if (parts.length == 3) {
        // HH:MM:SS format
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      } else {
        // Try parsing as total seconds
        final totalSeconds = int.parse(durationStr);
        return Duration(seconds: totalSeconds);
      }
    } catch (e) {
      return null;
    }
  }
}