import 'package:flutter/foundation.dart';
import '../models/podcast.dart';
import 'podcast_service.dart';
import 'opml_service.dart';

class PodcastAppState extends ChangeNotifier {
  final List<Podcast> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;

  List<Podcast> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;
  bool get isImporting => _isImporting;
  int get importProgress => _importProgress;
  int get importTotal => _importTotal;

  Future<void> initialize() async {
    if (_initialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final savedSubscriptions = await PodcastService.getAllSubscriptions();
      _subscriptions.clear();
      _subscriptions.addAll(savedSubscriptions);
      _initialized = true;
    } catch (e) {
      _error = 'Failed to load subscriptions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubscription(String rssUrl) async {
    if (_subscriptions.any((podcast) => podcast.rssUrl == rssUrl)) {
      _error = 'Already subscribed to this podcast';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final podcast = await PodcastService.addPodcastSubscription(rssUrl);
      _subscriptions.add(podcast);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSubscription(Podcast podcast) async {
    try {
      await PodcastService.removePodcastSubscription(podcast);
      _subscriptions.remove(podcast);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove subscription: $e';
      notifyListeners();
    }
  }

  Future<void> refreshPodcast(Podcast podcast) async {
    try {
      final refreshed = await PodcastService.refreshPodcast(podcast);
      final index = _subscriptions.indexWhere((p) => p.id == podcast.id);
      if (index != -1) {
        _subscriptions[index] = refreshed;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh podcast: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> importOpmlPodcasts(List<OpmlOutline> outlines) async {
    _isImporting = true;
    _importProgress = 0;
    _importTotal = outlines.length;
    _error = null;
    notifyListeners();

    int imported = 0;
    int skipped = 0;

    for (int i = 0; i < outlines.length; i++) {
      final outline = outlines[i];

      try {
        if (_subscriptions.any((p) => p.rssUrl == outline.xmlUrl)) {
          skipped++;
        } else {
          await addSubscription(outline.xmlUrl);
          if (_error == null) {
            imported++;
          } else {
            skipped++;
            clearError();
          }
        }
      } catch (e) {
        skipped++;
      }

      _importProgress = i + 1;
      notifyListeners();
    }

    _isImporting = false;
    _importProgress = 0;
    _importTotal = 0;

    if (imported > 0 || skipped > 0) {
      _error = null;
    }

    notifyListeners();
  }
}