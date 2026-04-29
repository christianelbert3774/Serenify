import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../core/audio/audio_session_manager.dart';
import 'widgets/noise_selector.dart';
import 'widgets/soundscape_grid.dart';

/// HomeScreen — layar utama Serenify
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final mixer = ref.read(audioMixerProvider);
    await mixer.init();

    // Setup audio session
    await AudioSessionManager.init(
      onPause: () => mixer.stopAll(),
      onResume: () {},
      onDuck: (volume) => mixer.setNoiseVolume(volume * 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    if (!mixer.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Preparing audio...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/image/applogocream.png', width: 130),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // Noise selector
            const NoiseSelector(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Soundscape grid
            const SoundscapeGrid(),

            const SizedBox(height: 24),

            // Stop all button
            _buildStopAllButton(theme, mixer),
          ],
        ),
      ),
    );
  }

  Widget _buildStopAllButton(ThemeData theme, AudioMixerNotifier mixer) {
    final hasAnyActive = mixer.noiseIsPlaying || mixer.layers.any((l) => l.isActive);

    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: hasAnyActive ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: hasAnyActive ? () => mixer.stopAll() : null,
          icon: const Icon(Icons.stop_circle_outlined, size: 20),
          label: const Text('Stop All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
