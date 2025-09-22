import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/podcast.dart';
import 'services/podcast_service.dart';
import 'screens/episode_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PodcastAppState(),
      child: MaterialApp(
        title: 'Castaway',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class PodcastAppState extends ChangeNotifier {
  final List<Podcast> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Podcast> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      final podcast = await PodcastService.fetchPodcast(rssUrl);
      _subscriptions.add(podcast);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeSubscription(Podcast podcast) {
    _subscriptions.remove(podcast);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Castaway'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PodcastAppState>(
        builder: (context, appState, child) {
          if (appState.subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No podcasts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first podcast subscription',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSubscriptionDialog(context),
                    icon: Icon(Icons.add),
                    label: Text('Add Podcast'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (appState.error != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(child: Text(appState.error!)),
                      IconButton(
                        onPressed: appState.clearError,
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: appState.subscriptions.length,
                  itemBuilder: (context, index) {
                    final podcast = appState.subscriptions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: podcast.imageUrl != null
                          ? NetworkImage(podcast.imageUrl!)
                          : null,
                        child: podcast.imageUrl == null
                          ? Icon(Icons.mic)
                          : null,
                      ),
                      title: Text(podcast.title),
                      subtitle: Text(podcast.author ?? ''),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => appState.removeSubscription(podcast),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EpisodeListScreen(podcast: podcast),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final controller = TextEditingController();
    final appState = Provider.of<PodcastAppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Podcast Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'RSS Feed URL',
                hintText: 'https://example.com/feed.xml',
              ),
              keyboardType: TextInputType.url,
            ),
            if (appState.isLoading) ...[
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: appState.isLoading ? null : () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await appState.addSubscription(url);
                if (context.mounted && appState.error == null) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
