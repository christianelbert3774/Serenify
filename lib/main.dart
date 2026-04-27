import 'package:flutter/material.dart';
import 'core/audio/audio_mixer.dart';
import 'core/audio/audio_session_manager.dart';
import 'core/models/soundscape_layer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MixerTestPage());
  }
}

class MixerTestPage extends StatefulWidget {
  const MixerTestPage({super.key});
  @override
  State<MixerTestPage> createState() => _MixerTestPageState();
}

class _MixerTestPageState extends State<MixerTestPage> {
  final AudioMixer _mixer = AudioMixer();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _mixer.init();

    // Setup audio session
    await AudioSessionManager.init(
      onPause: () => _mixer.stopAll(),
      onResume: () {},
      onDuck: (volume) {
        // Sederhanakan: duck noise volume saja
        _mixer.setNoiseVolume(volume * 0.7);
      },
    );

    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _mixer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Mixer Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === NOISE SECTION ===
            const Text('NOISE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildNoiseControls(),
            const SizedBox(height: 8),
            _buildNoiseVolumeSlider(),

            const Divider(height: 32),

            // === SOUNDSCAPE SECTION ===
            const Text('SOUNDSCAPES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._mixer.layers.map(_buildSoundscapeTile),

            const Divider(height: 32),

            // === GLOBAL CONTROLS ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _mixer.stopAll();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('⏹ Stop All', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Noise type toggle buttons
  Widget _buildNoiseControls() {
    return Row(
      children: NoiseType.values.map((type) {
        final isActive = _mixer.activeNoiseType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isActive) {
                    _mixer.stopNoise();
                  } else {
                    _mixer.playNoise(type);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? _noiseColor(type) : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  color: isActive ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Noise volume slider
  Widget _buildNoiseVolumeSlider() {
    return Row(
      children: [
        const Text('Noise Vol'),
        Expanded(
          child: Slider(
            value: _mixer.noiseVolume,
            onChanged: (v) {
              setState(() => _mixer.setNoiseVolume(v));
            },
          ),
        ),
        Text('${(_mixer.noiseVolume * 100).round()}%'),
      ],
    );
  }

  /// Single soundscape layer tile with toggle + volume
  Widget _buildSoundscapeTile(SoundscapeLayer layer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(layer.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(layer.name, style: const TextStyle(fontSize: 16)),
                ),
                Switch(
                  value: layer.isActive,
                  onChanged: (_) async {
                    await _mixer.toggleSoundscape(layer.id);
                    setState(() {});
                  },
                ),
              ],
            ),
            if (layer.isActive)
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Slider(
                      value: layer.volume,
                      onChanged: (v) async {
                        await _mixer.setSoundscapeVolume(layer.id, v);
                        setState(() {});
                      },
                    ),
                  ),
                  Text('${(layer.volume * 100).round()}%'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _noiseColor(NoiseType type) {
    return switch (type) {
      NoiseType.white => Colors.blueGrey,
      NoiseType.pink => Colors.pink,
      NoiseType.brown => Colors.brown,
    };
  }
}