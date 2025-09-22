import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final AudioPlayerService _audioPlayerService;
  late final AudioPlayer _player;

  AudioPlayerHandler(this._audioPlayerService, this._player) {
    _init();
  }

  Future<void> _init() async {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.loading:
        case ProcessingState.buffering:
          playbackState.add(PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            processingState: AudioProcessingState.buffering,
            playing: false,
          ));
        case ProcessingState.ready:
          playbackState.add(PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              if (state.playing) MediaControl.pause else MediaControl.play,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            processingState: AudioProcessingState.ready,
            playing: state.playing,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
            queueIndex: 0,
          ));
        case ProcessingState.completed:
          playbackState.add(PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            processingState: AudioProcessingState.completed,
            playing: false,
          ));
        case ProcessingState.idle:
          playbackState.add(PlaybackState(
            controls: [],
            processingState: AudioProcessingState.idle,
            playing: false,
          ));
      }
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      final currentState = playbackState.valueOrNull;
      if (currentState != null) {
        playbackState.add(currentState.copyWith(
          updatePosition: position,
        ));
      }
    });
  }

  @override
  Future<void> play() async {
    await _audioPlayerService.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayerService.seekTo(position);
  }

  @override
  Future<void> skipToNext() async {
    await _audioPlayerService.nextEpisode();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayerService.previousEpisode();
  }

  @override
  Future<void> seekForward(bool begin) async {
    if (begin) {
      await _audioPlayerService.skipForward();
    }
  }

  @override
  Future<void> seekBackward(bool begin) async {
    if (begin) {
      await _audioPlayerService.skipBackward();
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayerService.stop();
    await super.stop();
  }

  // Method to update media item when episode changes
  void setMediaItem(String title, String artist, String? artUri) {
    mediaItem.add(MediaItem(
      id: title,
      album: artist,
      title: title,
      artist: artist,
      artUri: artUri != null ? Uri.parse(artUri) : null,
      duration: _player.duration,
    ));
  }

  // Method to sync with AudioPlayerService
  void syncWithPlayerService() {
    final episode = _audioPlayerService.currentEpisode;
    final podcast = _audioPlayerService.currentPodcast;

    if (episode != null && podcast != null) {
      setMediaItem(
        episode.title,
        podcast.title,
        episode.imageUrl ?? podcast.imageUrl,
      );
    }
  }
}