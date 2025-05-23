import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class DataMigration {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateAudioFiles() async {
    final audioDir = Directory('assets/audio');
    final List<FileSystemEntity> files = audioDir.listSync();

    for (var file in files) {
      if (file is File) {
        final fileName = path.basename(file.path);
        final category = _getCategoryFromFileName(fileName);
        
        try {
          // Upload file to Firebase Storage
          final ref = _storage.ref().child('audio/$fileName');
          await ref.putFile(file);
          final downloadUrl = await ref.getDownloadURL();

          // Add metadata to Firestore
          await _firestore.collection('audio').add({
            'name': _getDisplayName(fileName),
            'category': category,
            'url': downloadUrl,
            'duration': await _getAudioDuration(file),
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('Successfully migrated: $fileName');
        } catch (e) {
          print('Error migrating $fileName: $e');
        }
      }
    }
  }

  String _getCategoryFromFileName(String fileName) {
    if (fileName.contains('meditation') || 
        fileName.contains('om') || 
        fileName.contains('bowls')) {
      return 'Meditation';
    }
    return 'Nature';
  }

  String _getDisplayName(String fileName) {
    // Remove extension and convert to title case
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<int> _getAudioDuration(File file) async {
    // In a real app, you would use a proper audio metadata reader
    // For now, return a default duration
    return 300; // 5 minutes in seconds
  }
}