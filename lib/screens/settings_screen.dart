import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/opml_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Import/Export'),
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Import OPML'),
            subtitle: Text('Import podcast subscriptions from an OPML file'),
            trailing: _isImporting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.chevron_right),
            enabled: !_isImporting,
            onTap: _importOpml,
          ),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Export OPML'),
            subtitle: Text('Export your podcast subscriptions to an OPML file'),
            trailing: _isExporting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.chevron_right),
            enabled: !_isExporting,
            onTap: _exportOpml,
          ),
          Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('About OPML'),
            subtitle: Text('Learn about OPML format for podcast subscriptions'),
            trailing: Icon(Icons.chevron_right),
            onTap: _showOpmlInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _importOpml() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final outlines = await OpmlService.importFromFile(filePath);

        if (outlines.isEmpty) {
          _showMessage('No valid podcast feeds found in the OPML file.');
          return;
        }

        final shouldImport = await _showImportConfirmation(outlines.length);
        if (!shouldImport) return;

        if (!mounted) return;
        final appState = Provider.of<PodcastAppState>(context, listen: false);
        int imported = 0;
        int skipped = 0;

        for (final outline in outlines) {
          try {
            // Check if already subscribed
            if (appState.subscriptions.any((p) => p.rssUrl == outline.xmlUrl)) {
              skipped++;
              continue;
            }

            await appState.addSubscription(outline.xmlUrl);
            if (appState.error == null) {
              imported++;
            } else {
              skipped++;
              appState.clearError(); // Clear error for next attempt
            }
          } catch (e) {
            skipped++;
          }
        }

        if (mounted) {
          _showMessage('Import completed: $imported added, $skipped skipped');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to import OPML: $e');
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _exportOpml() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final appState = Provider.of<PodcastAppState>(context, listen: false);
      final podcasts = appState.subscriptions;

      if (podcasts.isEmpty) {
        if (mounted) {
          _showMessage('No podcast subscriptions to export.');
        }
        return;
      }

      final opmlContent = OpmlService.generateOpml(podcasts);

      // Get a temporary directory to save the file
      final directory = await getTemporaryDirectory();
      final fileName = 'castaway_subscriptions_${DateTime.now().millisecondsSinceEpoch}.opml';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(opmlContent);

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Castaway Podcast Subscriptions');

      if (mounted) {
        _showMessage('OPML file exported and ready to share.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to export OPML: $e');
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<bool> _showImportConfirmation(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Podcasts'),
        content: Text('Found $count podcast feeds. This will attempt to subscribe to all of them. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Import'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showOpmlInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About OPML'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OPML (Outline Processor Markup Language) is a standard format for sharing lists of podcast subscriptions.'),
            SizedBox(height: 16),
            Text('You can:'),
            Text('• Export your subscriptions to share with others'),
            Text('• Import subscriptions from other podcast apps'),
            Text('• Backup your subscription list'),
            SizedBox(height: 16),
            Text('Most podcast applications support OPML import/export.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}