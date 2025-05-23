import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class Sound {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final Duration? duration;

  Sound({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.duration,
  });
}

class ModernAudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State variables
  Sound? _currentSound;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _volume = 0.7;
  String? _lastError;

  // Streams for position and duration
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // Define your audio assets here
  final List<Sound> _sounds = [
    // Nature Sounds
    Sound(
      id: 'ocean',
      name: 'Ocean Waves',
      category: 'Nature',
      assetPath: 'audio/ocean.mp3',
      duration: Duration(minutes: 10),
    ),
    Sound(
      id: 'rain',
      name: 'Rain Sounds',
      category: 'Nature',
      assetPath: 'audio/rain.mp3',
      duration: Duration(minutes: 8),
    ),
    Sound(
      id: 'forest',
      name: 'Forest Ambience',
      category: 'Nature',
      assetPath: 'audio/forest.mp3',
      duration: Duration(minutes: 12),
    ),
    Sound(
      id: 'thunder',
      name: 'Thunder Storm',
      category: 'Nature',
      assetPath: 'audio/thunder.mp3',
      duration: Duration(minutes: 15),
    ),
    Sound(
      id: 'campfire',
      name: 'Campfire Crackling',
      category: 'Nature',
      assetPath: 'audio/campfire.mp3',
      duration: Duration(minutes: 20),
    ),
    Sound(
      id: 'wind',
      name: 'Gentle Wind',
      category: 'Nature',
      assetPath: 'audio/wind.mp3',
      duration: Duration(minutes: 18),
    ),

    Sound(
      id: 'meditation',
      name: 'Meditation Bell',
      category: 'Meditation',
      assetPath: 'audio/meditation_bell.wav',
      duration: Duration(minutes: 3),
    ),
    Sound(
      id: 'bowls',
      name: 'Singing Bowls',
      category: 'Meditation',
      assetPath: 'audio/singing_bowls.wav',
      duration: Duration(minutes: 7),
    ),
    Sound(
      id: 'chanting',
      name: 'Om Chanting',
      category: 'Meditation',
      assetPath: 'audio/om_chanting.mp3',
      duration: Duration(minutes: 6),
    ),

    // Additional sounds
    Sound(
      id: 'birds',
      name: 'Bird Songs',
      category: 'Nature',
      assetPath: 'audio/birds.wav',
      duration: Duration(minutes: 14),
    ),
    Sound(
      id: 'stream',
      name: 'Flowing Stream',
      category: 'Nature',
      assetPath: 'audio/stream.wav',
      duration: Duration(minutes: 16),
    ),
  ];

  // Getters
  Sound? get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  double get volume => _volume;
  String? get lastError => _lastError;
  List<Sound> get allSounds => _sounds;

  // Check if a specific sound is currently playing
  bool isSoundPlaying(String soundId) {
    return _currentSound?.id == soundId && _isPlaying;
  }

  // Check if a specific sound is currently selected (playing or paused)
  bool isSoundSelected(String soundId) {
    return _currentSound?.id == soundId;
  }

  // Get unique categories
  List<String> get categories {
    final Set<String> categorySet = {'All'};
    for (final sound in _sounds) {
      categorySet.add(sound.category);
    }
    return categorySet.toList();
  }

  // Get sounds by category
  List<Sound> getSoundsByCategory(String category) {
    if (category == 'All') {
      return _sounds;
    }
    return _sounds.where((sound) => sound.category == category).toList();
  }

  ModernAudioService() {
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    // Set initial volume
    _audioPlayer.setVolume(_volume);

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      print('Player state changed to: $state');

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
          // Optionally restart the sound for ambient sounds
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

    // Listen for errors
    _audioPlayer.onLog.listen((String message) {
      if (message.contains('ERROR') || message.contains('error')) {
        print('AudioPlayer Log: $message');
      }
    });
  }

  // Play a sound
  Future<void> playSound(Sound sound) async {
    try {
      _setError(null); // Clear previous errors

      // If the same sound is playing, pause it
      if (_currentSound?.id == sound.id && _isPlaying) {
        await pauseSound();
        return;
      }

      // If the same sound is paused, resume it
      if (_currentSound?.id == sound.id && !_isPlaying) {
        await resumeSound();
        return;
      }

      // Set current sound immediately for UI feedback
      _setCurrentSound(sound);
      _setBuffering(true);
      _setPlaying(false); // Will be set to true by state listener

      // Stop current sound if playing a different one
      if (_currentSound?.id != sound.id) {
        await _audioPlayer.stop();
      }

      // Play the new sound from assets
      await _audioPlayer.play(AssetSource(sound.assetPath));

      print('Successfully started playing: ${sound.name}');
    } catch (e) {
      _setBuffering(false);
      _setPlaying(false);

      String errorMessage = 'Failed to play ${sound.name}. Please check if the audio file exists in assets folder.';
      _setError(errorMessage);

      print('Error playing sound: $e');
      print('Asset path: ${sound.assetPath}');

      // Clear current sound on error
      _setCurrentSound(null);
    }
  }

  // Pause the current sound
  Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
      print('Paused: ${_currentSound?.name}');
    } catch (e) {
      print('Error pausing sound: $e');
      _setError('Failed to pause sound');
    }
  }

  // Resume the current sound
  Future<void> resumeSound() async {
    try {
      await _audioPlayer.resume();
      print('Resumed: ${_currentSound?.name}');
    } catch (e) {
      print('Error resuming sound: $e');
      _setError('Failed to resume sound');
    }
  }

  // Stop the current sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _setCurrentSound(null);
      print('Stopped audio playback');
    } catch (e) {
      print('Error stopping sound: $e');
      _setError('Failed to stop sound');
    }
  }

  // Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      _setError('Failed to seek');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
      print('Volume set to: ${(_volume * 100).round()}%');
    } catch (e) {
      print('Error setting volume: $e');
      _setError('Failed to set volume');
    }
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }

  // Private helper methods with improved state management
  void _setCurrentSound(Sound? sound) {
    if (_currentSound != sound) {
      _currentSound = sound;
      notifyListeners();
      print('Current sound set to: ${sound?.name ?? 'null'}');
    }
  }

  void _setPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
      print('Playing state set to: $playing');
    }
  }

  void _setBuffering(bool buffering) {
    if (_isBuffering != buffering) {
      _isBuffering = buffering;
      notifyListeners();
      print('Buffering state set to: $buffering');
    }
  }

  void _setError(String? error) {
    if (_lastError != error) {
      _lastError = error;
      notifyListeners();
      if (error != null) {
        print('Error set: $error');
      }
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Optional: Get sound by ID
  Sound? getSoundById(String id) {
    try {
      return _sounds.firstWhere((sound) => sound.id == id);
    } catch (e) {
      return null;
    }
  }

  // Optional: Add custom sound
  void addSound(Sound sound) {
    _sounds.add(sound);
    notifyListeners();
  }

  // Optional: Remove sound
  void removeSound(String id) {
    _sounds.removeWhere((sound) => sound.id == id);
    if (_currentSound?.id == id) {
      stopSound();
    }
    notifyListeners();
  }
}