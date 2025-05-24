import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class AudioMigrationService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define your audio files with their categories
  final List<Map<String, String>> audioFiles = [
    {'file': 'meditation_bells.mp3', 'name': 'Meditation Bells', 'category': 'Meditation'},
    {'file': 'ocean_waves.mp3', 'name': 'Ocean Waves', 'category': 'Nature'},
    {'file': 'forest_sounds.mp3', 'name': 'Forest Sounds', 'category': 'Nature'},
    {'file': 'rain_drops.mp3', 'name': 'Rain Drops', 'category': 'Nature'},
    {'file': 'tibetan_bowls.mp3', 'name': 'Tibetan Bowls', 'category': 'Meditation'},
    {'file': 'campfire.mp3', 'name': 'Campfire', 'category': 'Nature'},
    {'file': 'wind_chimes.mp3', 'name': 'Wind Chimes', 'category': 'Meditation'},
    {'file': 'thunderstorm.mp3', 'name': 'Thunderstorm', 'category': 'Nature'},
    {'file': 'bird_songs.mp3', 'name': 'Bird Songs', 'category': 'Nature'},
    {'file': 'gentle_stream.mp3', 'name': 'Gentle Stream', 'category': 'Nature'},
  ];

  Future<void> migrateAllAudioFiles() async {
    print('Starting audio migration...');

    try {
      for (int i = 0; i < audioFiles.length; i++) {
        final audioFile = audioFiles[i];
        print('Processing ${i + 1}/${audioFiles.length}: ${audioFile['name']}');

        await _migrateAudioFile(
          audioFile['file']!,
          audioFile['name']!,
          audioFile['category']!,
        );

        // Add small delay to avoid overwhelming Firebase
        await Future.delayed(Duration(milliseconds: 500));
      }

      print('Audio migration completed successfully!');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  Future<void> _migrateAudioFile(String fileName, String displayName, String category) async {
    try {
      // 1. Load audio file from assets
      final ByteData data = await rootBundle.load('assets/audio/$fileName');
      final Uint8List bytes = data.buffer.asUint8List();

      print('Loaded $fileName (${bytes.length} bytes)');

      // 2. Upload to Firebase Storage
      final String storagePath = 'audio/$fileName';
      final Reference storageRef = _storage.ref().child(storagePath);

      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'originalName': displayName,
          'category': category,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final UploadTask uploadTask = storageRef.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      // 3. Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Uploaded to Firebase Storage: $downloadUrl');

      // 4. Save metadata to Firestore
      await _saveAudioMetadata(fileName, displayName, category, downloadUrl);

      print('Successfully migrated: $displayName');

    } catch (e) {
      print('Error migrating $fileName: $e');
      rethrow;
    }
  }

  Future<void> _saveAudioMetadata(String fileName, String displayName, String category, String url) async {
    try {
      // Use filename without extension as document ID for consistency
      final String docId = path.basenameWithoutExtension(fileName).toLowerCase().replaceAll(' ', '_');

      final Map<String, dynamic> audioData = {
        'name': displayName,
        'category': category,
        'url': url,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'playCount': 0,
        'tags': _generateTags(displayName, category),
      };

      await _firestore.collection('audio').doc(docId).set(audioData);
      print('Saved metadata to Firestore with ID: $docId');

    } catch (e) {
      print('Error saving metadata: $e');
      rethrow;
    }
  }

  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }

  List<String> _generateTags(String name, String category) {
    final tags = <String>[];

    // Add category as tag
    tags.add(category.toLowerCase());

    // Add words from name as tags
    tags.addAll(
      name.toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList(),
    );

    // Add common related tags based on category
    if (category.toLowerCase() == 'nature') {
      tags.addAll(['relaxing', 'ambient', 'peaceful']);
    } else if (category.toLowerCase() == 'meditation') {
      tags.addAll(['mindfulness', 'zen', 'spiritual']);
    }

    return tags.toSet().toList(); // Remove duplicates
  }

  // Method to check if audio files exist in assets
  Future<bool> checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Method to verify migration by listing Firestore documents
  Future<void> verifyMigration() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('audio').get();

      print('\n=== Migration Verification ===');
      print('Found ${snapshot.docs.length} audio files in database:');

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('- ${data['name']} (${data['category']}) - ${doc.id}');
      }
      print('=== End Verification ===\n');

    } catch (e) {
      print('Error verifying migration: $e');
    }
  }

  // Method to clean up (delete all audio documents) - use with caution!
  Future<void> cleanupAudioCollection() async {
    try {
      print('WARNING: This will delete all documents in the audio collection!');

      final QuerySnapshot snapshot = await _firestore.collection('audio').get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        print('Deleted: ${doc.id}');
      }

      print('Cleanup completed. Deleted ${snapshot.docs.length} documents.');

    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }
}