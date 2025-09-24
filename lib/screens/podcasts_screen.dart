import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/podcast_app_state.dart';
import '../widgets/podcast_tile.dart';
import 'episode_list_screen.dart';
import 'settings_screen.dart';

class PodcastsScreen extends StatefulWidget {
  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PodcastAppState>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Castaway'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              final appState = Provider.of<PodcastAppState>(context, listen: false);
              await appState.initialize();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PodcastAppState>(
        builder: (context, appState, child) {
          if (!appState.initialized && appState.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

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
              if (appState.isImporting)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Importing podcast subscriptions...',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (appState.importTotal > 0)
                              Text(
                                '${appState.importProgress} of ${appState.importTotal} podcasts',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: appState.subscriptions.length,
                    itemBuilder: (context, index) {
                      final podcast = appState.subscriptions[index];
                      return PodcastTile(
                        podcast: podcast,
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