import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:just_audio/just_audio.dart';
import '../models/soundscape_layer.dart';
import 'noise_generator.dart';

/// Tipe noise yang tersedia
enum NoiseType { white, pink, brown }

/// AudioMixer — orchestrator yang mengelola noise engine + soundscape players
class AudioMixer {
  final NoiseGenerator _noiseGenerator = NoiseGenerator();

  // === Noise state ===
  NoiseType? _activeNoiseType;
  bool _noiseIsPlaying = false;
  double _noiseVolume = 0.7;

  // === Soundscape state ===
  /// Map dari soundscape ID ke AudioPlayer instance
  final Map<String, AudioPlayer> _soundscapePlayers = {};

  /// Daftar semua soundscape layers (mutable state)
  List<SoundscapeLayer> _layers = [];

  // === Getters ===
  NoiseType? get activeNoiseType => _activeNoiseType;
  bool get noiseIsPlaying => _noiseIsPlaying;
  double get noiseVolume => _noiseVolume;
  List<SoundscapeLayer> get layers => List.unmodifiable(_layers);

  /// Initialize mixer — setup PCM engine + prepare soundscape players
  Future<void> init() async {
    // Setup PCM audio untuk noise
    await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 1);
    await FlutterPcmSound.setFeedThreshold(8820);
    FlutterPcmSound.setFeedCallback(_onNoiseFeedCallback);

    // Init soundscape layers dari defaults
    _layers = defaultSoundscapes.map((s) => s.copyWith()).toList();

    // Create AudioPlayer untuk setiap soundscape
    for (final layer in _layers) {
      final player = AudioPlayer();
      await player.setAsset(layer.assetPath);
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(layer.volume);
      _soundscapePlayers[layer.id] = player;
    }
  }

  // =====================
  //  NOISE CONTROL
  // =====================

  /// Play noise type tertentu
  void playNoise(NoiseType type) {
    _activeNoiseType = type;
    _noiseIsPlaying = true;
    // Trigger initial feed
    _onNoiseFeedCallback(0);
  }

  /// Stop noise
  void stopNoise() {
    _noiseIsPlaying = false;
    _activeNoiseType = null;
  }

  /// Set noise volume (0.0 - 1.0)
  void setNoiseVolume(double volume) {
    _noiseVolume = volume.clamp(0.0, 1.0);
  }

  /// PCM feed callback — generate noise samples on demand
  void _onNoiseFeedCallback(int remainingFrames) {
    if (!_noiseIsPlaying || _activeNoiseType == null) return;

    const int framesToGenerate = 4410; // ~100ms
    List<double> samples;

    switch (_activeNoiseType!) {
      case NoiseType.white:
        samples = _noiseGenerator.generateWhiteNoise(framesToGenerate);
      case NoiseType.pink:
        samples = _noiseGenerator.generatePinkNoise(framesToGenerate);
      case NoiseType.brown:
        samples = _noiseGenerator.generateBrownNoise(framesToGenerate);
    }

    // Apply volume ke samples
    final int16Samples = samples.map((s) {
      final scaled = (s * _noiseVolume).clamp(-1.0, 1.0);
      return (scaled * 32767).round();
    }).toList();

    FlutterPcmSound.feed(PcmArrayInt16.fromList(int16Samples));
  }

  // =====================
  //  SOUNDSCAPE CONTROL
  // =====================

  /// Toggle soundscape on/off
  Future<void> toggleSoundscape(String layerId) async {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index == -1) return;

    final layer = _layers[index];
    final player = _soundscapePlayers[layerId];
    if (player == null) return;

    if (layer.isActive) {
      // Stop
      await player.pause();
      _layers[index] = layer.copyWith(isActive: false);
    } else {
      // Play
      await player.seek(Duration.zero);
      await player.play();
      _layers[index] = layer.copyWith(isActive: true);
    }
  }

  /// Set volume untuk satu soundscape layer
  Future<void> setSoundscapeVolume(String layerId, double volume) async {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index == -1) return;

    final clampedVolume = volume.clamp(0.0, 1.0);
    _layers[index] = _layers[index].copyWith(volume: clampedVolume);
    await _soundscapePlayers[layerId]?.setVolume(clampedVolume);
  }

  /// Stop semua audio (noise + semua soundscape)
  Future<void> stopAll() async {
    stopNoise();
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        await _soundscapePlayers[_layers[i].id]?.pause();
        _layers[i] = _layers[i].copyWith(isActive: false);
      }
    }
  }

  /// Dispose semua resources
  Future<void> dispose() async {
    stopNoise();
    FlutterPcmSound.release();
    for (final player in _soundscapePlayers.values) {
      await player.dispose();
    }
    _soundscapePlayers.clear();
  }
}
