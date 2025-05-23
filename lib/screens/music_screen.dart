import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key? key}) : super(key: key);

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<ModernAudioService>(context);
    final categories = audioService.categories;
    final sounds = audioService.getSoundsByCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sounds & Music'),
        actions: [
          if (audioService.currentSound != null)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: () => audioService.stopSound(),
              tooltip: 'Stop All',
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message if any
          if (audioService.lastError != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audioService.lastError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade600),
                    onPressed: () => audioService.clearError(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Player controls if sound is playing
          if (audioService.currentSound != null)
            _buildMusicPlayer(context, audioService),

          // Category filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.transparent,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : AppColors.divider,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sound list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Available Sounds (${sounds.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          Expanded(
            child: sounds.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No sounds available in this category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Make sure audio files are placed in assets/audio/ folder',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: sounds.length,
              itemBuilder: (context, index) {
                final sound = sounds[index];
                final isCurrentSound = audioService.currentSound?.id == sound.id;
                final isPlaying = audioService.isPlaying && isCurrentSound;
                final isBuffering = audioService.isBuffering && isCurrentSound;

                return FadeInUp(
                  duration: Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 50),
                  child: Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        audioService.playSound(sound);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(sound.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  _getSoundIcon(sound.id),
                                  color: _getCategoryColor(sound.category),
                                  size: 28,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sound.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: isCurrentSound ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(sound.category).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          sound.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getCategoryColor(sound.category),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isBuffering)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getCategoryColor(sound.category),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: isCurrentSound ? _getCategoryColor(sound.category) : AppColors.textSecondary,
                                  size: 36,
                                ),
                                onPressed: () {
                                  audioService.playSound(sound);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer(BuildContext context, ModernAudioService audioService) {
    final currentSound = audioService.currentSound!;

    return FadeInDown(
      duration: Duration(milliseconds: 400),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(currentSound.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getSoundIcon(currentSound.id),
                      color: _getCategoryColor(currentSound.category),
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentSound.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (audioService.isBuffering)
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(currentSound.category),
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          audioService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: _getCategoryColor(currentSound.category),
                          size: 36,
                        ),
                        onPressed: () {
                          if (audioService.isPlaying) {
                            audioService.pauseSound();
                          } else {
                            audioService.resumeSound();
                          }
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.stop_circle,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                      onPressed: () {
                        audioService.stopSound();
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Progress bar
            StreamBuilder<Duration>(
              stream: audioService.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration>(
                  stream: audioService.durationStream,
                  builder: (context, durationSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = durationSnapshot.data ?? Duration.zero;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatDuration(position),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Expanded(
                              child: Slider(
                                value: duration.inMilliseconds > 0
                                    ? position.inMilliseconds / duration.inMilliseconds
                                    : 0.0,
                                onChanged: (value) {
                                  final newPosition = Duration(
                                    milliseconds: (value * duration.inMilliseconds).round(),
                                  );
                                  audioService.seek(newPosition);
                                },
                                activeColor: _getCategoryColor(currentSound.category),
                                inactiveColor: _getCategoryColor(currentSound.category).withOpacity(0.3),
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Volume control
                        Row(
                          children: [
                            Icon(
                              Icons.volume_down,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            Expanded(
                              child: Slider(
                                value: audioService.volume,
                                onChanged: (value) {
                                  audioService.setVolume(value);
                                },
                                activeColor: _getCategoryColor(currentSound.category),
                                inactiveColor: _getCategoryColor(currentSound.category).withOpacity(0.3),
                              ),
                            ),
                            Icon(
                              Icons.volume_up,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${(audioService.volume * 100).round()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Meditation':
        return AppColors.secondary;
      case 'Nature':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  IconData _getSoundIcon(String soundId) {
    switch (soundId) {
      case 'ocean':
        return Icons.waves;
      case 'rain':
        return Icons.grain;
      case 'forest':
        return Icons.forest;
      case 'meditation':
        return Icons.self_improvement;
      case 'bowls':
        return Icons.music_note;
      case 'thunder':
        return Icons.thunderstorm;
      case 'campfire':
        return Icons.local_fire_department;
      case 'wind':
        return Icons.air;
      case 'chanting':
        return Icons.record_voice_over;
      case 'birds':
        return Icons.flutter_dash;
      case 'stream':
        return Icons.water;
      default:
        return Icons.music_note;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}