import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_player_service.dart';
import 'services/audio_handler.dart';
import 'services/podcast_app_state.dart';
import 'screens/podcasts_screen.dart';
import 'widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.initialize();

  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(audioPlayerService, audioPlayerService.player),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.castaway.audio',
      androidNotificationChannelName: 'Castaway Audio',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  // Connect the audio service back to the player service
  audioPlayerService.setAudioHandler(audioHandler);

  runApp(MyApp(
    audioPlayerService: audioPlayerService,
    audioHandler: audioHandler,
  ));
}

class MyApp extends StatelessWidget {
  final AudioPlayerService audioPlayerService;
  final AudioPlayerHandler audioHandler;

  const MyApp({
    super.key,
    required this.audioPlayerService,
    required this.audioHandler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PodcastAppState()),
        ChangeNotifierProvider.value(value: audioPlayerService),
      ],
      child: MaterialApp(
        title: 'Castaway',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: AppWithPlayer(),
      ),
    );
  }
}

class AppWithPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PodcastsScreen(),
      bottomNavigationBar: MiniPlayer(),
    );
  }
}
