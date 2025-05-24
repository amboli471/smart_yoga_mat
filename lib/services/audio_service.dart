import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Sound {
  final String id;
  final String name;
  final String category;
  final String url;
  final Duration? duration;
  final List<String>? tags;
  final DateTime? createdAt;
  final int playCount;

  Sound({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    this.duration,
    this.tags,
    this.createdAt,
    this.playCount = 0,
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
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      playCount: data['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'url': url,
      'duration': duration?.inSeconds,
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'playCount': playCount,
    };
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
  bool _isLooping = true; // Enable looping by default
  double _volume = 0.7;
  String? _lastError;
  List<Sound> _sounds = [];
  bool _isLoading = false;

  // Streams for position and duration
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  // Getters
  Sound? get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isLooping => _isLooping;
  double get volume => _volume;
  String? get lastError => _lastError;
  List<Sound> get allSounds => _sounds;
  bool get isLoading => _isLoading;

  ModernAudioService() {
    _initializeAudioPlayer();
    _loadSoundsFromFirestore();
  }

  Future<void> _loadSoundsFromFirestore() async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('audio')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _sounds = snapshot.docs.map((doc) => Sound.fromFirestore(doc)).toList();

      print('Loaded ${_sounds.length} sounds from Firestore');
      notifyListeners();

    } catch (e) {
      print('Error loading sounds: $e');
      _setError('Failed to load sounds from database');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSounds() async {
    await _loadSoundsFromFirestore();
  }

  void _initializeAudioPlayer() {
    _audioPlayer.setVolume(_volume);

    // Set loop mode to single track repeat
    _audioPlayer.setLoopMode(LoopMode.one);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      _setPlaying(isPlaying);

      switch (processingState) {
        case ProcessingState.idle:
          _setBuffering(false);
          break;
        case ProcessingState.loading:
          _setBuffering(true);
          break;
        case ProcessingState.buffering:
          _setBuffering(true);
          break;
        case ProcessingState.ready:
          _setBuffering(false);
          break;
        case ProcessingState.completed:
          _setPlaying(false);
          _setBuffering(false);
          // With loop mode enabled, this shouldn't trigger often
          // but if it does, restart the current sound
          if (_currentSound != null && _isLooping) {
            _restartCurrentSound();
          }
          break;
      }
    });

    // Listen to duration changes to update sound duration in database
    _audioPlayer.durationStream.listen((duration) {
      if (_currentSound != null && duration != null) {
        _updateSoundDuration(_currentSound!, duration);
      }
    });
  }

  Future<void> playSound(Sound sound) async {
    try {
      _setError(null);

      // If same sound is playing, pause it
      if (_currentSound?.id == sound.id && _isPlaying) {
        await pauseSound();
        return;
      }

      // If same sound is paused, resume it
      if (_currentSound?.id == sound.id && !_isPlaying) {
        await resumeSound();
        return;
      }

      _setCurrentSound(sound);
      _setBuffering(true);
      _setPlaying(false);

      // Stop current audio if different sound
      if (_currentSound?.id != sound.id) {
        await _audioPlayer.stop();
      }

      // Set the audio source and play
      await _audioPlayer.setUrl(sound.url);
      await _audioPlayer.play();

      // Update play count
      await _incrementPlayCount(sound);

    } catch (e) {
      _setBuffering(false);
      _setPlaying(false);
      _setError('Failed to play ${sound.name}');
      _setCurrentSound(null);
      print('Error playing sound: $e');
    }
  }

  Future<void> _restartCurrentSound() async {
    if (_currentSound != null) {
      try {
        await _audioPlayer.seek(Duration.zero);
        if (_isLooping) {
          await _audioPlayer.play();
        }
      } catch (e) {
        print('Error restarting sound: $e');
      }
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
      await _audioPlayer.play();
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

  Future<void> toggleLoop() async {
    try {
      _isLooping = !_isLooping;
      await _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
      notifyListeners();
    } catch (e) {
      print('Error toggling loop: $e');
      _setError('Failed to toggle loop mode');
    }
  }

  Future<void> setLooping(bool looping) async {
    try {
      _isLooping = looping;
      await _audioPlayer.setLoopMode(looping ? LoopMode.one : LoopMode.off);
      notifyListeners();
    } catch (e) {
      print('Error setting loop mode: $e');
      _setError('Failed to set loop mode');
    }
  }

  Future<void> _incrementPlayCount(Sound sound) async {
    try {
      await _firestore.collection('audio').doc(sound.id).update({
        'playCount': FieldValue.increment(1),
        'lastPlayedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating play count: $e');
      // Don't show this error to user as it's not critical
    }
  }

  Future<void> _updateSoundDuration(Sound sound, Duration duration) async {
    try {
      // Only update if we don't have duration stored yet
      if (sound.duration == null) {
        await _firestore.collection('audio').doc(sound.id).update({
          'duration': duration.inSeconds,
        });
      }
    } catch (e) {
      print('Error updating sound duration: $e');
      // Don't show this error to user as it's not critical
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

  List<Sound> searchSounds(String query) {
    if (query.isEmpty) return _sounds;

    final lowercaseQuery = query.toLowerCase();
    return _sounds.where((sound) {
      return sound.name.toLowerCase().contains(lowercaseQuery) ||
          sound.category.toLowerCase().contains(lowercaseQuery) ||
          (sound.tags?.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ?? false);
    }).toList();
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

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
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