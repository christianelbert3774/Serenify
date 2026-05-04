import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:just_audio/just_audio.dart';
import '../models/soundscape_layer.dart';
import '../models/preset.dart';
import 'noise_generator.dart';

class AudioMixer {
  final NoiseGenerator _noiseGenerator = NoiseGenerator();

  FrequencyMode? _activeMode;
  bool _noiseIsPlaying = false;
  double _noiseVolume = 0.7;
  bool _isPaused = false;
  String? _activePresetName;

  final Map<String, AudioPlayer> _soundscapePlayers = {};
  List<SoundscapeLayer> _layers = [];

  FrequencyMode? get activeMode => _activeMode;
  bool get noiseIsPlaying => _noiseIsPlaying;
  double get noiseVolume => _noiseVolume;
  bool get isPaused => _isPaused;
  String? get activePresetName => _activePresetName;
  List<SoundscapeLayer> get layers => List.unmodifiable(_layers);
  bool get hasAnyActive => _noiseIsPlaying || _layers.any((l) => l.isActive);

  Future<void> init() async {
    await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 2);
    await FlutterPcmSound.setFeedThreshold(8820);
    FlutterPcmSound.setFeedCallback(_onFeedCallback);

    _layers = defaultSoundscapes.map((s) => s.copyWith()).toList();
    for (final layer in _layers) {
      final player = AudioPlayer();
      await player.setAsset(layer.assetPath);
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(layer.volume);
      _soundscapePlayers[layer.id] = player;
    }
  }

  // --- Frequency mode ---

  void playMode(FrequencyMode mode) {
    _activeMode = mode;
    _noiseIsPlaying = true;
    _isPaused = false;
    _noiseGenerator.reset();
    _onFeedCallback(0);
  }

  void stopMode() {
    _noiseIsPlaying = false;
    _activeMode = null;
  }

  void setNoiseVolume(double volume) {
    _noiseVolume = volume.clamp(0.0, 1.0);
  }

  void _onFeedCallback(int _) {
    if (!_noiseIsPlaying || _activeMode == null || _isPaused) return;
    final stereo = _noiseGenerator.generateStereo(_activeMode!, 4410);
    final int16 = stereo.map((s) =>
        ((s * _noiseVolume).clamp(-1.0, 1.0) * 32767).round()).toList();
    FlutterPcmSound.feed(PcmArrayInt16.fromList(int16));
  }

  // --- Soundscape ---

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
    final v = volume.clamp(0.0, 1.0);
    _layers[index] = _layers[index].copyWith(volume: v);
    await _soundscapePlayers[layerId]?.setVolume(v);
  }

  // --- Pause / Resume ---

  Future<void> pauseAll() async {
    _isPaused = true;
    for (final l in _layers) {
      if (l.isActive) await _soundscapePlayers[l.id]?.pause();
    }
  }

  Future<void> resumeAll() async {
    _isPaused = false;
    if (_noiseIsPlaying && _activeMode != null) _onFeedCallback(0);
    for (final l in _layers) {
      if (l.isActive) _soundscapePlayers[l.id]?.play();
    }
  }

  // --- Preset ---

  Preset capturePreset(String name) {
    return Preset(
      name: name,
      noiseType: _activeMode?.name,
      noiseVolume: _noiseVolume,
      activeSoundscapes: {
        for (final l in _layers.where((l) => l.isActive)) l.id: l.volume,
      },
      binauralEnabled: false,
    );
  }

  Future<void> applyPreset(Preset preset) async {
    await stopAll();
    _activePresetName = preset.name;

    if (preset.noiseType != null) {
      final mode = FrequencyMode.values.firstWhere(
        (m) => m.name == preset.noiseType,
        orElse: () => FrequencyMode.relax,
      );
      _noiseVolume = preset.noiseVolume;
      playMode(mode);
    }

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

  // --- Global ---

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
        final v = (_layers[i].volume * factor).clamp(0.0, 1.0);
        _layers[i] = _layers[i].copyWith(volume: v);
        await _soundscapePlayers[_layers[i].id]?.setVolume(v);
      }
    }
  }

  Future<void> dispose() async {
    stopMode();
    FlutterPcmSound.release();
    for (final p in _soundscapePlayers.values) {
      await p.dispose();
    }
    _soundscapePlayers.clear();
  }
}
