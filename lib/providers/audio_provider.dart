import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/audio/audio_mixer.dart';
import '../core/audio/noise_generator.dart';
import '../core/models/soundscape_layer.dart';
import '../core/models/preset.dart';
import '../core/models/custom_audio.dart';
import '../core/storage/preset_repository.dart';
import '../core/storage/custom_audio_repository.dart';
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
  List<CustomAudio> get customAudios => _mixer.customAudios;

  bool isCustomActive(String id) => _mixer.isCustomActive(id);
  double customVolume(String id) => _mixer.customVolume(id);

  Future<void> init() async {
    await _mixer.init();
    await NotificationService.init();

    // Wire notification action buttons to mixer
    NotificationService.onPause = () => togglePause();
    NotificationService.onStop  = () => stopAll();

    // Load custom audio from storage
    final customAudios = CustomAudioRepository.getAll();
    await _mixer.loadCustomAudios(customAudios);

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

    // Active custom audio
    final activeCustom = _mixer.customAudios
        .where((a) => _mixer.isCustomActive(a.id))
        .toList();
    if (activeCustom.length == 1) {
      parts.add(activeCustom.first.name);
    } else if (activeCustom.length > 1) {
      parts.add('${activeCustom.length} Custom');
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

  // ── Custom Audio ────────────────────────────────────────────────────────

  /// Opens file picker, imports selected audio file to private storage,
  /// and loads it into the mixer.
  Future<void> importCustomAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    // Copy to private storage + save to Hive
    await CustomAudioRepository.importFile(path);

    // Reload all custom audio into mixer
    final all = CustomAudioRepository.getAll();
    await _mixer.loadCustomAudios(all);
    notifyListeners();
  }

  Future<void> toggleCustomAudio(String id) async {
    await _mixer.toggleCustomAudio(id);
    await _syncNotif();
    notifyListeners();
  }

  Future<void> setCustomVolume(String id, double volume) async {
    await _mixer.setCustomVolume(id, volume);
    notifyListeners();
  }

  Future<void> deleteCustomAudio(CustomAudio audio) async {
    await _mixer.removeCustomAudio(audio.id);
    await CustomAudioRepository.delete(audio);
    await _syncNotif();
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
