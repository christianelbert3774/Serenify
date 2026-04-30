import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:just_audio/just_audio.dart';
import '../models/soundscape_layer.dart';
import '../models/preset.dart';
import 'noise_generator.dart';

/// AudioMixer — orchestrator: frequency modes + soundscapes + binaural + pause/resume
class AudioMixer {
  final NoiseGenerator _noiseGenerator = NoiseGenerator();

  // === Frequency mode state ===
  FrequencyMode? _activeMode;
  bool _noiseIsPlaying = false;
  double _noiseVolume = 0.7;
  bool _binauralEnabled = true; // Default ON

  // === Global state ===
  bool _isPaused = false;
  String? _activePresetName;

  // === Soundscape state ===
  final Map<String, AudioPlayer> _soundscapePlayers = {};
  List<SoundscapeLayer> _layers = [];

  // === Getters ===
  FrequencyMode? get activeMode => _activeMode;
  bool get noiseIsPlaying => _noiseIsPlaying;
  double get noiseVolume => _noiseVolume;
  bool get binauralEnabled => _binauralEnabled;
  bool get isPaused => _isPaused;
  String? get activePresetName => _activePresetName;
  List<SoundscapeLayer> get layers => List.unmodifiable(_layers);

  /// Check if any audio is active
  bool get hasAnyActive =>
      _noiseIsPlaying || _layers.any((l) => l.isActive);

  Future<void> init() async {
    await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 2);
    await FlutterPcmSound.setFeedThreshold(8820);
    FlutterPcmSound.setFeedCallback(_onNoiseFeedCallback);

    _layers = defaultSoundscapes.map((s) => s.copyWith()).toList();
    for (final layer in _layers) {
      final player = AudioPlayer();
      await player.setAsset(layer.assetPath);
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(layer.volume);
      _soundscapePlayers[layer.id] = player;
    }
  }

  // =====================
  //  FREQUENCY MODE
  // =====================

  void playMode(FrequencyMode mode) {
    _activeMode = mode;
    _noiseIsPlaying = true;
    _isPaused = false;
    _noiseGenerator.resetPhases();
    _onNoiseFeedCallback(0);
  }

  void stopMode() {
    _noiseIsPlaying = false;
    _activeMode = null;
  }

  void setNoiseVolume(double volume) {
    _noiseVolume = volume.clamp(0.0, 1.0);
  }

  void setBinauralEnabled(bool enabled) {
    _binauralEnabled = enabled;
    if (enabled) _noiseGenerator.resetPhases();
  }

  void _onNoiseFeedCallback(int remainingFrames) {
    if (!_noiseIsPlaying || _activeMode == null || _isPaused) return;

    const int framesToGenerate = 4410;
    final stereoSamples = _noiseGenerator.generateStereoNoise(
      _activeMode!,
      framesToGenerate,
      binauralEnabled: _binauralEnabled,
    );

    final int16Samples = stereoSamples.map((s) {
      final scaled = (s * _noiseVolume).clamp(-1.0, 1.0);
      return (scaled * 32767).round();
    }).toList();

    FlutterPcmSound.feed(PcmArrayInt16.fromList(int16Samples));
  }



  // =====================
  //  SOUNDSCAPE CONTROL
  // =====================

  Future<void> toggleSoundscape(String layerId) async {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index == -1) return;

    final layer = _layers[index];
    final player = _soundscapePlayers[layerId];
    if (player == null) return;

    if (layer.isActive) {
      _layers[index] = layer.copyWith(isActive: false);
      await player.pause();
    } else {
      _layers[index] = layer.copyWith(isActive: true);
      _isPaused = false;
      await player.seek(Duration.zero);
      player.play();
    }
  }

  Future<void> setSoundscapeVolume(String layerId, double volume) async {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index == -1) return;

    final clampedVolume = volume.clamp(0.0, 1.0);
    _layers[index] = _layers[index].copyWith(volume: clampedVolume);
    await _soundscapePlayers[layerId]?.setVolume(clampedVolume);
  }

  // =====================
  //  PAUSE / RESUME
  // =====================

  Future<void> pauseAll() async {
    _isPaused = true;
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        await _soundscapePlayers[_layers[i].id]?.pause();
      }
    }
  }

  Future<void> resumeAll() async {
    _isPaused = false;
    // Resume noise
    if (_noiseIsPlaying && _activeMode != null) {
      _onNoiseFeedCallback(0);
    }
    // Resume soundscapes
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        _soundscapePlayers[_layers[i].id]?.play();
      }
    }
  }

  // =====================
  //  PRESET
  // =====================

  Preset capturePreset(String name) {
    final activeSoundscapes = <String, double>{};
    for (final layer in _layers) {
      if (layer.isActive) {
        activeSoundscapes[layer.id] = layer.volume;
      }
    }
    return Preset(
      name: name,
      noiseType: _activeMode?.name,
      noiseVolume: _noiseVolume,
      activeSoundscapes: activeSoundscapes,
      binauralEnabled: _binauralEnabled,
    );
  }

  Future<void> applyPreset(Preset preset) async {
    await stopAll();
    _activePresetName = preset.name;

    // Apply frequency mode
    if (preset.noiseType != null) {
      final mode = FrequencyMode.values.firstWhere(
        (m) => m.name == preset.noiseType,
        orElse: () => FrequencyMode.relax,
      );
      _noiseVolume = preset.noiseVolume;
      _binauralEnabled = preset.binauralEnabled;
      playMode(mode);
    }

    // Apply soundscapes
    for (final entry in preset.activeSoundscapes.entries) {
      final index = _layers.indexWhere((l) => l.id == entry.key);
      if (index == -1) continue;
      final player = _soundscapePlayers[entry.key];
      if (player == null) continue;

      await player.setVolume(entry.value);
      _layers[index] = _layers[index].copyWith(isActive: true, volume: entry.value);
      await player.seek(Duration.zero);
      player.play();
    }
  }

  // =====================
  //  GLOBAL
  // =====================

  Future<void> stopAll() async {
    stopMode();
    _activePresetName = null;
    _isPaused = false;
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        _layers[i] = _layers[i].copyWith(isActive: false);
        await _soundscapePlayers[_layers[i].id]?.pause();
      }
    }
  }

  Future<void> setMasterVolume(double factor) async {
    _noiseVolume = (_noiseVolume * factor).clamp(0.0, 1.0);
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        final newVol = (_layers[i].volume * factor).clamp(0.0, 1.0);
        _layers[i] = _layers[i].copyWith(volume: newVol);
        await _soundscapePlayers[_layers[i].id]?.setVolume(newVol);
      }
    }
  }

  Future<void> dispose() async {
    stopMode();

    FlutterPcmSound.release();
    for (final player in _soundscapePlayers.values) {
      await player.dispose();
    }
    _soundscapePlayers.clear();
  }
}
