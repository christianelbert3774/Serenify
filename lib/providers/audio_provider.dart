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

    // Wire notification action buttons to mixer
    NotificationService.onPause = () => togglePause();
    NotificationService.onStop  = () => stopAll();

    _isInitialized = true;
    notifyListeners();
  }

  // ── Notification helpers ────────────────────────────────────────────────

  /// Builds a human-readable title from whatever is currently active.
  String _notifTitle() {
    // Preset takes priority
    if (_mixer.activePresetName != null) return _mixer.activePresetName!;

    final parts = <String>[];

    // Active frequency mode
    if (_mixer.activeMode != null) {
      final n = _mixer.activeMode!.name;
      parts.add(n[0].toUpperCase() + n.substring(1));
    }

    // Active soundscapes
    final active = _mixer.layers.where((l) => l.isActive).toList();
    if (active.length == 1) {
      parts.add(active.first.name);
    } else if (active.length > 1) {
      parts.add('${active.length} Soundscapes');
    }

    return parts.isEmpty ? 'Serenify' : parts.join(' + ');
  }

  /// Show or update notification if anything is playing; dismiss if nothing.
  Future<void> _syncNotif() async {
    if (_mixer.hasAnyActive) {
      await NotificationService.show(_notifTitle(), paused: _mixer.isPaused);
    } else {
      await NotificationService.dismiss();
    }
  }

  // ── Frequency mode ──────────────────────────────────────────────────────

  void playMode(FrequencyMode mode) {
    _mixer.playMode(mode);
    _syncNotif();
    notifyListeners();
  }

  void stopMode() {
    _mixer.stopMode();
    _syncNotif();
    notifyListeners();
  }

  void setNoiseVolume(double volume) {
    _mixer.setNoiseVolume(volume);
    notifyListeners();
  }

  // ── Soundscape ──────────────────────────────────────────────────────────

  Future<void> toggleSoundscape(String layerId) async {
    await _mixer.toggleSoundscape(layerId);
    await _syncNotif();
    notifyListeners();
  }

  Future<void> setSoundscapeVolume(String layerId, double volume) async {
    await _mixer.setSoundscapeVolume(layerId, volume);
    notifyListeners();
  }

  // ── Pause / Resume ──────────────────────────────────────────────────────

  Future<void> pauseAll() async {
    await _mixer.pauseAll();
    await _syncNotif();
    notifyListeners();
  }

  Future<void> resumeAll() async {
    await _mixer.resumeAll();
    await _syncNotif();
    notifyListeners();
  }

  Future<void> togglePause() async {
    _mixer.isPaused ? await resumeAll() : await pauseAll();
  }

  // ── Preset ──────────────────────────────────────────────────────────────

  Preset capturePreset(String name) => _mixer.capturePreset(name);

  Future<void> applyPreset(Preset preset) async {
    await _mixer.applyPreset(preset);
    await _syncNotif();
    notifyListeners();
  }

  // ── Global ──────────────────────────────────────────────────────────────

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

// ── Providers ───────────────────────────────────────────────────────────────

final audioMixerProvider = ChangeNotifierProvider<AudioMixerNotifier>((ref) {
  final n = AudioMixerNotifier();
  ref.onDispose(() => n.disposeMixer());
  return n;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final presetsProvider = StateProvider<List<Preset>>((ref) {
  return PresetRepository.getPresets();
});
