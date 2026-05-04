import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/audio_mixer.dart';
import '../core/audio/noise_generator.dart';
import '../core/models/soundscape_layer.dart';
import '../core/models/preset.dart';
import '../core/storage/preset_repository.dart';
import '../core/services/notification_service.dart';

class AudioMixerNotifier extends ChangeNotifier {
  final AudioMixer _mixer = AudioMixer();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FrequencyMode? get activeMode => _mixer.activeMode;
  bool get noiseIsPlaying => _mixer.noiseIsPlaying;
  double get noiseVolume => _mixer.noiseVolume;
  bool get isPaused => _mixer.isPaused;
  bool get hasAnyActive => _mixer.hasAnyActive;
  String? get activePresetName => _mixer.activePresetName;
  List<SoundscapeLayer> get layers => _mixer.layers;

  Future<void> init() async {
    await _mixer.init();
    await NotificationService.init();
    // Wire notification buttons → mixer actions
    NotificationService.onPause  = () => togglePause();
    NotificationService.onStop   = () => stopAll();
    _isInitialized = true;
    notifyListeners();
  }

  void playMode(FrequencyMode mode) {
    _mixer.playMode(mode);
    notifyListeners();
  }

  void stopMode() {
    _mixer.stopMode();
    notifyListeners();
  }

  void setNoiseVolume(double volume) {
    _mixer.setNoiseVolume(volume);
    notifyListeners();
  }

  Future<void> toggleSoundscape(String layerId) async {
    await _mixer.toggleSoundscape(layerId);
    notifyListeners();
  }

  Future<void> setSoundscapeVolume(String layerId, double volume) async {
    await _mixer.setSoundscapeVolume(layerId, volume);
    notifyListeners();
  }

  Future<void> pauseAll() async {
    await _mixer.pauseAll();
    if (_mixer.activePresetName != null) {
      await NotificationService.show(_mixer.activePresetName!, paused: true);
    }
    notifyListeners();
  }

  Future<void> resumeAll() async {
    await _mixer.resumeAll();
    if (_mixer.activePresetName != null) {
      await NotificationService.show(_mixer.activePresetName!, paused: false);
    }
    notifyListeners();
  }

  Future<void> togglePause() async {
    _mixer.isPaused ? await resumeAll() : await pauseAll();
  }

  Preset capturePreset(String name) => _mixer.capturePreset(name);

  Future<void> applyPreset(Preset preset) async {
    await _mixer.applyPreset(preset);
    await NotificationService.show(preset.name, paused: false);
    notifyListeners();
  }

  Future<void> stopAll() async {
    await _mixer.stopAll();
    await NotificationService.dismiss();
    notifyListeners();
  }

  Future<void> setMasterVolume(double factor) async {
    await _mixer.setMasterVolume(factor);
    notifyListeners();
  }

  Future<void> disposeMixer() async {
    await NotificationService.dismiss();
    await _mixer.dispose();
  }
}

final audioMixerProvider = ChangeNotifierProvider<AudioMixerNotifier>((ref) {
  final n = AudioMixerNotifier();
  ref.onDispose(() => n.disposeMixer());
  return n;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final presetsProvider = StateProvider<List<Preset>>((ref) {
  return PresetRepository.getPresets();
});
