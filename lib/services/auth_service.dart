import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;
  late final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  AuthService() {
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        notifyListeners();
      });

      print('AuthService initialized successfully');
    } catch (e) {
      print('Error initializing AuthService: $e');
      _isInitialized = false;
    }
  }

  User? get currentUser {
    if (!_isInitialized) return null;
    return _auth.currentUser;
  }

  bool get isAuthenticated {
    if (!_isInitialized) return false;
    return currentUser != null;
  }

  Stream<User?> get authStateChanges {
    if (!_isInitialized) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  bool get isInitialized => _isInitialized;

  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await userCredential.user!.updateDisplayName(name);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Error during sign up: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password provided is too weak.');
        case 'email-already-in-use':
          throw Exception('An account already exists for that email.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        default:
          throw Exception('Failed to create account: ${e.message}');
      }
    } catch (e) {
      print('Error during sign up: $e');
      throw Exception('Failed to create account. Please try again.');
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Error during sign in: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'wrong-password':
          throw Exception('Wrong password provided.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception('Failed to sign in: ${e.message}');
      }
    } catch (e) {
      print('Error during sign in: $e');
      throw Exception('Failed to sign in. Please check your credentials.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create/update user profile in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'lastSignIn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Error during Google sign in: ${e.code} - ${e.message}');
      throw Exception('Failed to sign in with Google: ${e.message}');
    } catch (e) {
      print('Error during Google sign in: $e');
      throw Exception('Failed to sign in with Google. Please try again.');
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      print('Error during password reset: $e');
      throw Exception('Failed to send password reset email.');
    }
  }
}