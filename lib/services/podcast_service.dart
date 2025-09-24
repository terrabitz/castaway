import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../models/podcast.dart';
import '../database/database_helper.dart';

class PodcastService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  static Podcast parseRss(String rssXml, String rssUrl) {
    final document = XmlDocument.parse(rssXml);
    final channel = document.findAllElements('channel').first;

    final title = _getElementText(channel, 'title') ?? 'Unknown Podcast';
    final description = _getElementText(channel, 'description') ?? '';
    final imageUrl = _extractImageUrl(channel);
    final author = _getElementText(channel, 'itunes:author') ??
                  _getElementText(channel, 'managingEditor');

    final episodes = <Episode>[];
    final items = channel.findAllElements('item');

    for (final item in items) {
      final episode = parseEpisode(item, imageUrl);
      if (episode != null) {
        episodes.add(episode);
      }
    }

    return Podcast(
      title: title,
      description: description,
      rssUrl: rssUrl,
      imageUrl: imageUrl,
      author: author,
      episodes: episodes,
      lastFetched: DateTime.now(),
    );
  }

  static Future<Podcast> fetchPodcast(String rssUrl) async {
    try {
      final response = await http.get(Uri.parse(rssUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }

      final podcast = parseRss(response.body, rssUrl);

      final existing = await _dbHelper.getPodcastByRssUrl(rssUrl);
      if (existing != null) {
        final updatedPodcast = podcast.copyWith(id: existing.id, sortOrder: existing.sortOrder);
        await _dbHelper.updatePodcast(updatedPodcast);
        await _dbHelper.updatePodcastEpisodes(existing.id!, podcast.episodes);
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
    await _dbHelper.updatePodcastEpisodes(id, podcast.episodes);
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

  static Episode? parseEpisode(XmlElement item, String? fallbackImageUrl) {
    try {
      final title = _getElementText(item, 'title') ?? 'Unknown Episode';
      final description = _getElementText(item, 'description') ??
                         _getElementText(item, 'itunes:summary') ?? '';
      final audioUrl = _extractAudioUrl(item);
      final pubDateStr = _getElementText(item, 'pubDate');
      final durationStr = _getElementText(item, 'itunes:duration');
      final episodeImageUrl = _extractImageUrl(item) ?? fallbackImageUrl;

      if (audioUrl == null) return null;

      final pubDate = _parsePubDate(pubDateStr);
      if (pubDate == null && pubDateStr != null) {
        print('Warning: Failed to parse pubDate: "$pubDateStr" for episode: "$title"');
      }
      final finalPubDate = pubDate ?? DateTime.now();
      final duration = _parseDuration(durationStr);

      return Episode(
        title: title,
        description: description,
        audioUrl: audioUrl,
        pubDate: finalPubDate,
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
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // First try standard DateTime.parse
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Handle the specific format: "Mon, 22 Sep 2025 14:00:00 GMT"
        // Convert GMT to +0000 for DateTime.parse compatibility
        String normalizedDate = dateStr
            .replaceAll(' GMT', ' +0000')
            .replaceAll(' UTC', ' +0000');

        // Try parsing the normalized date
        return DateTime.parse(normalizedDate);
      } catch (e2) {
        try {
          // Try RFC 2822 format using DateFormat (fallback)
          final rfc2822Format = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');
          // Remove timezone suffix for this parser
          String dateWithoutTz = dateStr.replaceAll(RegExp(r'\s+(GMT|UTC|[+-]\d{4})$'), '');
          return rfc2822Format.parse(dateWithoutTz);
        } catch (e3) {
          try {
            // Manual parsing for the exact format: "Mon, 22 Sep 2025 14:00:00 GMT"
            final regex = RegExp(r'\w{3}, (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})');
            final match = regex.firstMatch(dateStr);

            if (match != null) {
              final day = int.parse(match.group(1)!);
              final monthStr = match.group(2)!;
              final year = int.parse(match.group(3)!);
              final hour = int.parse(match.group(4)!);
              final minute = int.parse(match.group(5)!);
              final second = int.parse(match.group(6)!);

              final monthMap = {
                'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
                'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
              };

              final month = monthMap[monthStr];
              if (month != null) {
                return DateTime(year, month, day, hour, minute, second);
              }
            }
          } catch (e4) {
            print('Failed to parse date: $dateStr - Error: $e4');
          }
        }
      }
    }

    return null;
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