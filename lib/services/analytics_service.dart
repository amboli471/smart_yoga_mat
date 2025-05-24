import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SessionData {
  final DateTime date;
  final int durationMinutes;
  final String type;
  
  const SessionData({
    required this.date,
    required this.durationMinutes,
    required this.type,
  });
}

class AnalyticsService extends ChangeNotifier {
  int _totalSessions = 0;
  int _totalMinutes = 0;
  String _mostUsedFeature = "";
  List<SessionData> _recentSessions = [];
  Map<String, int> _featureUsage = {};
  
  int get totalSessions => _totalSessions;
  int get totalMinutes => _totalMinutes;
  String get mostUsedFeature => _mostUsedFeature;
  List<SessionData> get recentSessions => _recentSessions;
  Map<String, int> get featureUsage => _featureUsage;
  
  AnalyticsService() {
    _loadData();
  }
  
  Future<void> _loadData() async {
    // In a real app, we would load from local storage or a server
    // For the prototype, we'll generate some sample data
    
    final prefs = await SharedPreferences.getInstance();
    _totalSessions = prefs.getInt('totalSessions') ?? 0;
    
    // Generate some sample data for the prototype
    if (_totalSessions == 0) {
      _generateSampleData();
    } else {
      _totalMinutes = prefs.getInt('totalMinutes') ?? 0;
      _mostUsedFeature = prefs.getString('mostUsedFeature') ?? "Warm-Up Mode";
      
      // Load feature usage
      final features = ['Warm-Up Mode', 'Relaxation Mode', 'Ocean Sounds'];
      for (final feature in features) {
        _featureUsage[feature] = prefs.getInt('feature_$feature') ?? 0;
      }
      
      // Generate some recent sessions
      _generateRecentSessions();
    }
    
    notifyListeners();
  }
  
  void _generateSampleData() {
    final random = Random();
    
    _totalSessions = 10 + random.nextInt(15);
    _totalMinutes = _totalSessions * (20 + random.nextInt(20));
    
    final features = ['Warm-Up Mode', 'Relaxation Mode', 'Ocean Sounds'];
    for (final feature in features) {
      _featureUsage[feature] = random.nextInt(20);
    }
    
    // Find most used feature
    int maxUsage = 0;
    for (final entry in _featureUsage.entries) {
      if (entry.value > maxUsage) {
        maxUsage = entry.value;
        _mostUsedFeature = entry.key;
      }
    }
    
    _generateRecentSessions();
    _saveData();
  }
  
  void _generateRecentSessions() {
    final random = Random();
    final types = ['Morning Yoga', 'Relaxation', 'Meditation', 'Stretching'];
    
    _recentSessions = [];
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      
      // Some days might not have sessions
      if (random.nextBool() || i < 2) {
        _recentSessions.add(SessionData(
          date: date,
          durationMinutes: 15 + random.nextInt(30),
          type: types[random.nextInt(types.length)],
        ));
      }
    }
  }
  
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('totalSessions', _totalSessions);
    await prefs.setInt('totalMinutes', _totalMinutes);
    await prefs.setString('mostUsedFeature', _mostUsedFeature);
    
    // Save feature usage
    for (final entry in _featureUsage.entries) {
      await prefs.setInt('feature_${entry.key}', entry.value);
    }
  }
  
  Future<void> recordSession(String type, int durationMinutes) async {
    _totalSessions++;
    _totalMinutes += durationMinutes;
    
    // Add to recent sessions
    _recentSessions.insert(0, SessionData(
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      type: type,
    ));
    
    // Keep only the most recent 7 sessions
    if (_recentSessions.length > 7) {
      _recentSessions = _recentSessions.sublist(0, 7);
    }
    
    await _saveData();
    notifyListeners();
  }
  
  Future<void> recordFeatureUsage(String feature) async {
    if (_featureUsage.containsKey(feature)) {
      _featureUsage[feature] = _featureUsage[feature]! + 1;
    } else {
      _featureUsage[feature] = 1;
    }
    
    // Update most used feature
    if (_featureUsage[feature]! > _featureUsage[_mostUsedFeature]!) {
      _mostUsedFeature = feature;
    }
    
    await _saveData();
    notifyListeners();
  }
}