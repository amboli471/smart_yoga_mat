import 'package:flutter/material.dart';
import '../services/audio_migration_service.dart';

class AudioMigrationScreen extends StatefulWidget {
  const AudioMigrationScreen({Key? key}) : super(key: key);

  @override
  State<AudioMigrationScreen> createState() => _AudioMigrationScreenState();
}

class _AudioMigrationScreenState extends State<AudioMigrationScreen> {
  final AudioMigrationService _migrationService = AudioMigrationService();
  bool _isLoading = false;
  String _status = 'Ready to migrate audio files';
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Migration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Migration Tool',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tool will upload your audio files from assets/audio/ to Firebase Storage and create database entries.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isLoading ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Migration buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startMigration,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.upload),
                  label: Text(_isLoading ? 'Migrating...' : 'Start Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifyMigration,
                  icon: const Icon(Icons.verified),
                  label: const Text('Verify Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCleanupDialog,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Cleanup Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // File list preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files to be migrated:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: _migrationService.audioFiles.length,
                        itemBuilder: (context, index) {
                          final file = _migrationService.audioFiles[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.music_note, size: 20),
                            title: Text(
                              file['name']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${file['category']} • ${file['file']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logs section
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Migration Logs:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: log.contains('Error')
                                      ? Colors.red
                                      : log.contains('Successfully')
                                      ? Colors.green
                                      : Colors.grey[700],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMigration() async {
    setState(() {
      _isLoading = true;
      _status = 'Migration in progress...';
      _logs.clear();
    });

    try {
      // Override print to capture logs
      void Function(Object?) originalPrint = print;
      print = (Object? object) {
        originalPrint(object);
        setState(() {
          _logs.add('${DateTime.now().toString().substring(11, 19)}: $object');
        });
      };

      await _migrationService.migrateAllAudioFiles();

      setState(() {
        _status = 'Migration completed successfully!';
      });

      // Restore original print
      print = originalPrint;

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      setState(() {
        _status = 'Migration failed: $e';
        _logs.add('${DateTime.now().toString().substring(11, 19)}: ERROR: $e');
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMigration() async {
    setState(() {
      _isLoading = true;
      _status = 'Verifying migration...';
    });

    try {
      // Override print to capture logs
      void Function(Object?) originalPrint = print;
      print = (Object? object) {
        originalPrint(object);
        setState(() {
          _logs.add('${DateTime.now().toString().substring(11, 19)}: $object');
        });
      };

      await _migrationService.verifyMigration();

      setState(() {
        _status = 'Migration verification completed';
      });

      // Restore original print
      print = originalPrint;

    } catch (e) {
      setState(() {
        _status = 'Verification failed: $e';
        _logs.add('${DateTime.now().toString().substring(11, 19)}: ERROR: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Cleanup Database'),
        content: const Text(
          'This will permanently delete ALL audio documents from the database. '
              'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCleanup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanup() async {
    setState(() {
      _isLoading = true;
      _status = 'Cleaning up database...';
    });

    try {
      // Override print to capture logs
      void Function(Object?) originalPrint = print;
      print = (Object? object) {
        originalPrint(object);
        setState(() {
          _logs.add('${DateTime.now().toString().substring(11, 19)}: $object');
        });
      };

      await _migrationService.cleanupDatabase();

      setState(() {
        _status = 'Database cleanup completed';
      });

      // Restore original print
      print = originalPrint;

      if (mounted) {
        _showInfoDialog('Cleanup Complete', 'All audio documents have been removed from the database.');
      }

    } catch (e) {
      setState(() {
        _status = 'Cleanup failed: $e';
        _logs.add('${DateTime.now().toString().substring(11, 19)}: ERROR: $e');
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = 'Logs cleared';
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Migration Successful'),
          ],
        ),
        content: const Text(
          'All audio files have been successfully migrated to Firebase Storage '
              'and database entries have been created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _verifyMigration();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify Migration', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Migration Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Migration failed with the following error:\n\n$error',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startMigration();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}