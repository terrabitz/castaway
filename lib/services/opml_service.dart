import 'dart:io';
import 'package:xml/xml.dart';
import '../models/podcast.dart';
import 'podcast_service.dart';

class OpmlService {
  static String generateOpml(List<Podcast> podcasts) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: 'Castaway Subscriptions');
        builder.element('dateCreated', nest: DateTime.now().toIso8601String());
        builder.element('dateModified', nest: DateTime.now().toIso8601String());
      });

      builder.element('body', nest: () {
        for (final podcast in podcasts) {
          builder.element('outline', attributes: {
            'type': 'rss',
            'text': podcast.title,
            'title': podcast.title,
            'xmlUrl': podcast.rssUrl,
            if (podcast.description.isNotEmpty) 'description': podcast.description,
            if (podcast.author != null) 'author': podcast.author!,
            if (podcast.imageUrl != null) 'imageUrl': podcast.imageUrl!,
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  static Future<void> exportToFile(String filePath, List<Podcast> podcasts) async {
    final opmlContent = generateOpml(podcasts);
    final file = File(filePath);
    await file.writeAsString(opmlContent);
  }

  static List<OpmlOutline> parseOpml(String opmlContent) {
    final document = XmlDocument.parse(opmlContent);
    final outlines = <OpmlOutline>[];

    final body = document.findAllElements('body').first;
    final outlineElements = body.findAllElements('outline');

    for (final outline in outlineElements) {
      final type = outline.getAttribute('type');
      final xmlUrl = outline.getAttribute('xmlUrl');

      // Only process RSS feeds
      if (type == 'rss' && xmlUrl != null && xmlUrl.isNotEmpty) {
        outlines.add(OpmlOutline(
          title: outline.getAttribute('title') ?? outline.getAttribute('text') ?? 'Unknown',
          xmlUrl: xmlUrl,
          description: outline.getAttribute('description'),
          author: outline.getAttribute('author'),
          imageUrl: outline.getAttribute('imageUrl'),
        ));
      }
    }

    return outlines;
  }

  static Future<List<OpmlOutline>> importFromFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return parseOpml(content);
  }

  static Future<List<Podcast>> importPodcasts(String opmlContent) async {
    final outlines = parseOpml(opmlContent);
    final podcasts = <Podcast>[];

    for (final outline in outlines) {
      try {
        final podcast = await PodcastService.fetchPodcast(outline.xmlUrl);
        podcasts.add(podcast);
      } catch (e) {
        // Skip podcasts that fail to fetch
        print('Failed to fetch podcast ${outline.title}: $e');
      }
    }

    return podcasts;
  }
}

class OpmlOutline {
  final String title;
  final String xmlUrl;
  final String? description;
  final String? author;
  final String? imageUrl;

  OpmlOutline({
    required this.title,
    required this.xmlUrl,
    this.description,
    this.author,
    this.imageUrl,
  });
}