import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class Sound {
  final String id;
  final String name;
  final String category;
  final String url;
  final Duration? duration;
  final List<String>? tags;
  int playCount;

  Sound({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    this.duration,
    this.tags,
    this.playCount = 0,
  });
}

class ModernAudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _loadSounds();
  }

  void _loadSounds() {
    try {
      _setLoading(true);
      _setError(null);

      // Define your audio files here - ALL meditation sounds now use "Meditation" category
      _sounds = [
        Sound(
          id: 'ocean_waves',
          name: 'Ocean Waves',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//ocean.mp3',
          tags: ['ocean', 'waves', 'water', 'relaxing'],
        ),
        Sound(
          id: 'rain_forest',
          name: 'Rain',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//rain.mp3',
          tags: ['rain', 'forest', 'nature', 'peaceful'],
        ),
        Sound(
          id: 'meditation_bell',
          name: 'Meditation Bells',
          category: 'Meditation', // Capitalized
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//meditation_bell.wav',
          tags: ['bell', 'meditation', 'zen', 'mindfulness'],
        ),
        Sound(
          id: 'thunder_storm',
          name: 'Thunder Storm',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//thunder.mp3',
          tags: ['thunder', 'storm', 'rain', 'dramatic'],
        ),
        Sound(
          id: 'campfire',
          name: 'Campfire',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//campfire.mp3',
          tags: ['fire', 'crackling', 'camping', 'cozy'],
        ),
        Sound(
          id: 'wind_chimes',
          name: 'Wind',
          category: 'Meditation', // Capitalized
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//wind.mp3',
          tags: ['chimes', 'wind', 'peaceful', 'gentle'],
        ),
        Sound(
          id: 'bird_songs',
          name: 'Bird chirps',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//birds.wav',
          tags: ['birds', 'singing', 'morning', 'nature'],
        ),
        Sound(
          id: 'flowing_stream',
          name: 'Flowing Stream',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//stream.wav',
          tags: ['stream', 'water', 'flowing', 'peaceful'],
        ),
        Sound(
          id: 'forest',
          name: 'Forest Sound',
          category: 'Nature',
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//forest.mp3',
          tags: ['forest', 'calm', 'peaceful'],
        ),
        Sound(
          id: 'om_chanting',
          name: 'Om Chants',
          category: 'Meditation', // Changed from lowercase 'meditation' to 'Meditation'
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//om_chanting.mp3',
          tags: ['focus', 'chant', 'calm', 'peaceful'],
        ),
        Sound(
          id: 'singing_bowls',
          name: 'Singing Bowls',
          category: 'Meditation', // Changed from lowercase 'meditation' to 'Meditation'
          url: 'https://uvcwuwlolhbsshlpditb.supabase.co/storage/v1/object/public/audio//singing_bowls.wav',
          tags: ['focus', 'meditation', 'calm', 'peaceful'],
        ),
        // Add more sounds as needed
      ];

      print('Loaded ${_sounds.length} sounds');
      notifyListeners();

    } catch (e) {
      print('Error loading sounds: $e');
      _setError('Failed to load sounds');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSounds() async {
    _loadSounds();
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
      print('Playing sound from URL: ${sound.url}');
      await _audioPlayer.setUrl(sound.url);
      await _audioPlayer.play();

      // Increment play count locally
      sound.playCount++;

    } catch (e) {
      _setBuffering(false);
      _setPlaying(false);
      _setError('Failed to play ${sound.name}. Check if the audio file exists.');
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