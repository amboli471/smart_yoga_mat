import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/mat_connection_service.dart';
import 'services/audio_service.dart';
import 'services/product_service.dart';
import 'services/update_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'utils/data_migration.dart';
import 'firebase_options.dart'; // Make sure this exists
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Uncomment to run migration once
    // final migration = DataMigration();
    // await migration.migrateAudioFiles();

    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Don't continue if Firebase fails to initialize
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Firebase Initialization Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Double-check Firebase is ready
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorApp(error: snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthService()),
              ChangeNotifierProvider(create: (_) => MatConnectionService()),
              ChangeNotifierProvider(create: (_) => ModernAudioService()),
              ChangeNotifierProvider(create: (_) => ProductService()),
              ChangeNotifierProvider(create: (_) => UpdateService()),
              ChangeNotifierProvider(create: (_) => AnalyticsService()),
              Provider(create: (_) => FirestoreService()),
            ],
            child: MaterialApp(
              title: 'Smart Yoga Mat',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              debugShowCheckedModeBanner: false,
              home: AuthWrapper(),
            ),
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Firebase...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeApp() async {
    // Ensure Firebase is fully ready
    await Future.delayed(Duration(milliseconds: 100));

    // Verify Firebase apps are available
    final apps = Firebase.apps;
    if (apps.isEmpty) {
      throw Exception('No Firebase apps found after initialization');
    }

    // Test Firebase Auth is accessible
    try {
      FirebaseAuth.instance;
      print('Firebase Auth is ready');
    } catch (e) {
      throw Exception('Firebase Auth not ready: $e');
    }
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking authentication...'),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Authentication Error'),
                      SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasData) {
              return HomeScreen();
            }

            return LoginScreen();
          },
        );
      },
    );
  }
}