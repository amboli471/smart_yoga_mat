import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Products Collection
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('products').add(productData);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getProducts() {
    return _firestore.collection('products').snapshots();
  }

  // User Data
  Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Audio Files
  Future<String> uploadAudio(String fileName, Uint8List fileData) async {
    try {
      final ref = _storage.ref().child('audio/$fileName');
      await ref.putData(fileData);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading audio: $e');
      rethrow;
    }
  }

  Future<void> addAudioMetadata(Map<String, dynamic> audioData) async {
    try {
      await _firestore.collection('audio').add(audioData);
    } catch (e) {
      print('Error adding audio metadata: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAudioFiles() {
    return _firestore.collection('audio').snapshots();
  }

  // User Sessions
  Future<void> saveUserSession(String userId, Map<String, dynamic> sessionData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .add(sessionData);
    } catch (e) {
      print('Error saving user session: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUserSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // User Settings
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user settings: $e');
      rethrow;
    }
  }

  Stream<DocumentSnapshot> getUserSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .snapshots();
  }
}