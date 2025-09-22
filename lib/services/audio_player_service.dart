import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/podcast.dart';
import 'audio_handler.dart';

enum PlayerState { stopped, playing, paused, loading, buffering }

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayerHandler? _audioHandler;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  Episode? _currentEpisode;
  Podcast? _currentPodcast;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  Episode? get currentEpisode => _currentEpisode;
  Podcast? get currentPodcast => _currentPodcast;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isLoading => _playerState == PlayerState.loading;
  bool get hasEpisode => _currentEpisode != null;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  String get formattedPosition {
    final minutes = _position.inMinutes;
    final seconds = _position.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final minutes = _duration.inMinutes;
    final seconds = _duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void setAudioHandler(AudioPlayerHandler handler) {
    _audioHandler = handler;
  }

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _playerState = PlayerState.buffering;
        case ProcessingState.ready:
          _playerState = state.playing ? PlayerState.playing : PlayerState.paused;
        case ProcessingState.completed:
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        case ProcessingState.idle:
          _playerState = PlayerState.stopped;
      }
      notifyListeners();
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> playEpisode(Episode episode, Podcast podcast) async {
    try {
      _playerState = PlayerState.loading;
      _currentEpisode = episode;
      _currentPodcast = podcast;
      notifyListeners();

      // Update media notification with episode info
      _audioHandler?.setMediaItem(
        episode.title,
        podcast.title,
        episode.imageUrl ?? podcast.imageUrl,
      );

      await _player.setUrl(episode.audioUrl);
      await _player.play();
    } on PlayerInterruptedException catch (e) {
      // This call was interrupted since another audio source was loaded or the
      // player was stopped or disposed before this audio source could complete
      // loading.
      // See https://pub.dev/packages/just_audio#working-with-errors
      print("Connection aborted: ${e.message}");
    } catch (e) {
      _playerState = PlayerState.stopped;
      notifyListeners();
      throw Exception('Failed to play episode: $e');
    }
  }

  Future<void> play() async {
    if (_currentEpisode != null) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentEpisode = null;
    _currentPodcast = null;
    _position = Duration.zero;
    _playerState = PlayerState.stopped;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipForward([Duration duration = const Duration(seconds: 30)]) async {
    final newPosition = _position + duration;
    final maxPosition = _duration;
    await seekTo(newPosition > maxPosition ? maxPosition : newPosition);
  }

  Future<void> skipBackward([Duration duration = const Duration(seconds: 10)]) async {
    final newPosition = _position - duration;
    await seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> nextEpisode() async {
    if (_currentPodcast == null || _currentEpisode == null) return;

    final episodes = _currentPodcast!.episodes;
    final currentIndex = episodes.indexOf(_currentEpisode!);

    if (currentIndex < episodes.length - 1) {
      final nextEpisode = episodes[currentIndex + 1];
      await playEpisode(nextEpisode, _currentPodcast!);
    }
  }

  Future<void> previousEpisode() async {
    if (_currentPodcast == null || _currentEpisode == null) return;

    final episodes = _currentPodcast!.episodes;
    final currentIndex = episodes.indexOf(_currentEpisode!);

    if (currentIndex > 0) {
      final previousEpisode = episodes[currentIndex - 1];
      await playEpisode(previousEpisode, _currentPodcast!);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}