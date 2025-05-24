import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'audio_migration_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key? key}) : super(key: key);

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<ModernAudioService>(context);
    final categories = audioService.categories;
    final sounds = _searchQuery.isNotEmpty
        ? audioService.searchSounds(_searchQuery)
        : audioService.getSoundsByCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sounds & Music'),
        actions: [
          // Migration tool button (for development/admin)
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AudioMigrationScreen(),
                ),
              );
            },
            tooltip: 'Migration Tool',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => audioService.refreshSounds(),
            tooltip: 'Refresh Sounds',
          ),
          // Stop button
          if (audioService.currentSound != null)
            IconButton(
              icon: const Icon(Icons.stop),
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
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
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
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (audioService.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading sounds...'),
                ],
              ),
            ),

          // Player controls if sound is playing
          if (audioService.currentSound != null)
            _buildMusicPlayer(context, audioService),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sounds...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category filter (hidden when searching)
          if (_searchQuery.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ],

          // Sound list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Search Results (${sounds.length})'
                      : 'Available Sounds (${sounds.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (sounds.isNotEmpty)
                  Text(
                    '${sounds.where((s) => s.playCount > 0).length} played',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Sound list
          Expanded(
            child: sounds.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.music_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No sounds found for "$_searchQuery"'
                        : 'No sounds available in this category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try searching with different keywords'
                        : 'Use the migration tool to upload audio files',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => audioService.refreshSounds(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  final isCurrentSound = audioService.currentSound?.id == sound.id;
                  final isPlaying = audioService.isPlaying && isCurrentSound;
                  final isBuffering = audioService.isBuffering && isCurrentSound;

                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    delay: Duration(milliseconds: index * 50),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
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
                              const SizedBox(width: 16),
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
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                        const SizedBox(width: 8),
                                        if (sound.playCount > 0)
                                          Text(
                                            '${sound.playCount} plays',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer(BuildContext context, ModernAudioService audioService) {
    final currentSound = audioService.currentSound!;

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Text(
                        currentSound.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (audioService.isLooping)
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: _getCategoryColor(currentSound.category),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Looping',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getCategoryColor(currentSound.category),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loop toggle button
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: audioService.isLooping
                            ? _getCategoryColor(currentSound.category)
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => audioService.toggleLoop(),
                      tooltip: audioService.isLooping ? 'Disable Loop' : 'Enable Loop',
                    ),
                    if (audioService.isBuffering)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                      icon: const Icon(
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
            const SizedBox(height: 16),
            // Progress bar
            StreamBuilder<Duration>(
              stream: audioService.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
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
                        const SizedBox(height: 8),
                        // Volume control
                        Row(
                          children: [
                            const Icon(
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
                            const Icon(
                              Icons.volume_up,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
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
    switch (category.toLowerCase()) {
      case 'meditation':
        return AppColors.secondary;
      case 'nature':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  IconData _getSoundIcon(String soundId) {
    final id = soundId.toLowerCase();
    if (id.contains('ocean') || id.contains('wave')) return Icons.waves;
    if (id.contains('rain') || id.contains('drop')) return Icons.grain;
    if (id.contains('forest') || id.contains('tree')) return Icons.forest;
    if (id.contains('meditation') || id.contains('zen')) return Icons.self_improvement;
    if (id.contains('bowl') || id.contains('bell')) return Icons.music_note;
    if (id.contains('thunder') || id.contains('storm')) return Icons.thunderstorm;
    if (id.contains('fire') || id.contains('camp')) return Icons.local_fire_department;
    if (id.contains('wind') || id.contains('air')) return Icons.air;
    if (id.contains('chant') || id.contains('voice')) return Icons.record_voice_over;
    if (id.contains('bird') || id.contains('song')) return Icons.flutter_dash;
    if (id.contains('stream') || id.contains('water')) return Icons.water;
    if (id.contains('chime')) return Icons.notifications;
    return Icons.music_note;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}