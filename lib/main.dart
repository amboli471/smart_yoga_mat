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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    
    // Uncomment to run migration once
    // final migration = DataMigration();
    // await migration.migrateAudioFiles();
    
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
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