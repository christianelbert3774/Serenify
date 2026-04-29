import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/audio_mixer.dart';
import '../core/models/soundscape_layer.dart';

//  AudioMixer Notifier — reactive wrapper around AudioMixer
class AudioMixerNotifier extends ChangeNotifier {
  final AudioMixer _mixer = AudioMixer();
  bool _isInitialized = false;

  // === Getters (proxy ke AudioMixer) ===
  bool get isInitialized => _isInitialized;
  NoiseType? get activeNoiseType => _mixer.activeNoiseType;
  bool get noiseIsPlaying => _mixer.noiseIsPlaying;
  double get noiseVolume => _mixer.noiseVolume;
  List<SoundscapeLayer> get layers => _mixer.layers;

  /// Initialize semua audio resources
  Future<void> init() async {
    await _mixer.init();
    _isInitialized = true;
    notifyListeners();
  }

  // === Noise ===
  void playNoise(NoiseType type) {
    _mixer.playNoise(type);
    notifyListeners();
  }

  void stopNoise() {
    _mixer.stopNoise();
    notifyListeners();
  }

  void setNoiseVolume(double volume) {
    _mixer.setNoiseVolume(volume);
    notifyListeners();
  }

  // === Soundscape ===
  Future<void> toggleSoundscape(String layerId) async {
    await _mixer.toggleSoundscape(layerId);
    notifyListeners();
  }

  Future<void> setSoundscapeVolume(String layerId, double volume) async {
    await _mixer.setSoundscapeVolume(layerId, volume);
    notifyListeners();
  }

  // === Global ===
  Future<void> stopAll() async {
    await _mixer.stopAll();
    notifyListeners();
  }

  Future<void> disposeMixer() async {
    await _mixer.dispose();
  }
}

/// Provider utama — satu instance AudioMixerNotifier untuk seluruh app
final audioMixerProvider = ChangeNotifierProvider<AudioMixerNotifier>((ref) {
  final notifier = AudioMixerNotifier();
  ref.onDispose(() => notifier.disposeMixer());
  return notifier;
});

/// Provider untuk theme mode (dark/light)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
