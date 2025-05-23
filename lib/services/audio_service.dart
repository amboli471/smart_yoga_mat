import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Sound {
  final String id;
  final String name;
  final String category;
  final String url;
  final Duration? duration;

  Sound({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    this.duration,
  });

  factory Sound.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sound(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      url: data['url'] ?? '',
      duration: data['duration'] != null 
          ? Duration(seconds: data['duration']) 
          : null,
    );
  }
}

class ModernAudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State variables
  Sound? _currentSound;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _volume = 0.7;
  String? _lastError;
  List<Sound> _sounds = [];

  // Streams for position and duration
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // Getters
  Sound? get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  double get volume => _volume;
  String? get lastError => _lastError;
  List<Sound> get allSounds => _sounds;

  ModernAudioService() {
    _initializeAudioPlayer();
    _loadSoundsFromFirestore();
  }

  Future<void> _loadSoundsFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('audio').get();
      _sounds = snapshot.docs.map((doc) => Sound.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading sounds: $e');
      _setError('Failed to load sounds from database');
    }
  }

  void _initializeAudioPlayer() {
    _audioPlayer.setVolume(_volume);

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      switch (state) {
        case PlayerState.playing:
          _setPlaying(true);
          _setBuffering(false);
          break;
        case PlayerState.paused:
          _setPlaying(false);
          _setBuffering(false);
          break;
        case PlayerState.stopped:
          _setPlaying(false);
          _setBuffering(false);
          _setCurrentSound(null);
          break;
        case PlayerState.completed:
          _setPlaying(false);
          _setBuffering(false);
          if (_currentSound != null) {
            playSound(_currentSound!);
          }
          break;
        case PlayerState.disposed:
          _setPlaying(false);
          _setBuffering(false);
          _setCurrentSound(null);
          break;
      }
    });
  }

  Future<void> playSound(Sound sound) async {
    try {
      _setError(null);

      if (_currentSound?.id == sound.id && _isPlaying) {
        await pauseSound();
        return;
      }

      if (_currentSound?.id == sound.id && !_isPlaying) {
        await resumeSound();
        return;
      }

      _setCurrentSound(sound);
      _setBuffering(true);
      _setPlaying(false);

      if (_currentSound?.id != sound.id) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.play(UrlSource(sound.url));

    } catch (e) {
      _setBuffering(false);
      _setPlaying(false);
      _setError('Failed to play ${sound.name}');
      _setCurrentSound(null);
      print('Error playing sound: $e');
    }
  }

  Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing sound: $e');
      _setError('Failed to pause sound');
    }
  }

  Future<void> resumeSound() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print('Error resuming sound: $e');
      _setError('Failed to resume sound');
    }
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _setCurrentSound(null);
    } catch (e) {
      print('Error stopping sound: $e');
      _setError('Failed to stop sound');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      _setError('Failed to seek');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      print('Error setting volume: $e');
      _setError('Failed to set volume');
    }
  }

  List<String> get categories {
    final Set<String> categorySet = {'All'};
    for (final sound in _sounds) {
      categorySet.add(sound.category);
    }
    return categorySet.toList();
  }

  List<Sound> getSoundsByCategory(String category) {
    if (category == 'All') {
      return _sounds;
    }
    return _sounds.where((sound) => sound.category == category).toList();
  }

  void clearError() {
    _setError(null);
  }

  void _setCurrentSound(Sound? sound) {
    if (_currentSound != sound) {
      _currentSound = sound;
      notifyListeners();
    }
  }

  void _setPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }

  void _setBuffering(bool buffering) {
    if (_isBuffering != buffering) {
      _isBuffering = buffering;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_lastError != error) {
      _lastError = error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}