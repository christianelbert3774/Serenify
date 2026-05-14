import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:just_audio/just_audio.dart';
import '../models/soundscape_layer.dart';
import '../models/preset.dart';
import '../models/custom_audio.dart';
import 'noise_generator.dart';

class AudioMixer {
  final NoiseGenerator _noiseGenerator = NoiseGenerator();

  FrequencyMode? _activeMode;
  bool _noiseIsPlaying = false;
  double _noiseVolume = 0.7;
  bool _isPaused = false;
  String? _activePresetName;

  // Built-in soundscapes
  final Map<String, AudioPlayer> _soundscapePlayers = {};
  List<SoundscapeLayer> _layers = [];

  // Custom audio
  final Map<String, AudioPlayer> _customPlayers = {};
  final Map<String, bool> _customActive = {};
  final Map<String, double> _customVolume = {};
  List<CustomAudio> _customAudios = [];

  FrequencyMode? get activeMode => _activeMode;
  bool get noiseIsPlaying => _noiseIsPlaying;
  double get noiseVolume => _noiseVolume;
  bool get isPaused => _isPaused;
  String? get activePresetName => _activePresetName;
  List<SoundscapeLayer> get layers => List.unmodifiable(_layers);
  List<CustomAudio> get customAudios => List.unmodifiable(_customAudios);

  bool get hasAnyActive =>
      _noiseIsPlaying ||
      _layers.any((l) => l.isActive) ||
      _customActive.values.any((a) => a);

  bool isCustomActive(String id) => _customActive[id] ?? false;
  double customVolume(String id) => _customVolume[id] ?? 0.5;

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

  // --- Custom Audio ---

  /// Load all custom audio files from repository data.
  Future<void> loadCustomAudios(List<CustomAudio> audios) async {
    // Dispose players that no longer exist
    final newIds = audios.map((a) => a.id).toSet();
    for (final id in _customPlayers.keys.toList()) {
      if (!newIds.contains(id)) {
        await _customPlayers[id]?.dispose();
        _customPlayers.remove(id);
        _customActive.remove(id);
        _customVolume.remove(id);
      }
    }

    // Add new players
    for (final audio in audios) {
      if (_customPlayers.containsKey(audio.id)) continue;
      try {
        final player = AudioPlayer();
        await player.setFilePath(audio.filePath);
        await player.setLoopMode(LoopMode.all);
        await player.setVolume(0.5);
        _customPlayers[audio.id] = player;
        _customActive[audio.id] = false;
        _customVolume[audio.id] = 0.5;
      } catch (e) {
        // File corrupt or missing — skip gracefully
      }
    }
    _customAudios = List.of(audios);
  }

  Future<void> toggleCustomAudio(String id) async {
    final player = _customPlayers[id];
    if (player == null) return;
    final active = _customActive[id] ?? false;

    if (active) {
      await player.pause();
      _customActive[id] = false;
    } else {
      _isPaused = false;
      await player.seek(Duration.zero);
      player.play();
      _customActive[id] = true;
    }
  }

  Future<void> setCustomVolume(String id, double volume) async {
    final v = volume.clamp(0.0, 1.0);
    _customVolume[id] = v;
    await _customPlayers[id]?.setVolume(v);
  }

  Future<void> removeCustomAudio(String id) async {
    await _customPlayers[id]?.dispose();
    _customPlayers.remove(id);
    _customActive.remove(id);
    _customVolume.remove(id);
    _customAudios.removeWhere((a) => a.id == id);
  }

  // --- Pause / Resume ---

  Future<void> pauseAll() async {
    _isPaused = true;
    for (final l in _layers) {
      if (l.isActive) await _soundscapePlayers[l.id]?.pause();
    }
    for (final entry in _customActive.entries) {
      if (entry.value) await _customPlayers[entry.key]?.pause();
    }
  }

  Future<void> resumeAll() async {
    _isPaused = false;
    if (_noiseIsPlaying && _activeMode != null) _onFeedCallback(0);
    for (final l in _layers) {
      if (l.isActive) _soundscapePlayers[l.id]?.play();
    }
    for (final entry in _customActive.entries) {
      if (entry.value) _customPlayers[entry.key]?.play();
    }
  }

  // --- Preset ---

  Preset capturePreset(String name) {
    final map = <String, double>{};
    for (final l in _layers.where((l) => l.isActive)) {
      map[l.id] = l.volume;
    }
    // Include active custom audio in preset
    for (final a in _customAudios) {
      if (_customActive[a.id] == true) {
        map[a.id] = _customVolume[a.id] ?? 0.5;
      }
    }
    return Preset(
      name: name,
      noiseType: _activeMode?.name,
      noiseVolume: _noiseVolume,
      activeSoundscapes: map,
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
      // Try built-in soundscape first
      final index = _layers.indexWhere((l) => l.id == entry.key);
      if (index != -1) {
        final player = _soundscapePlayers[entry.key];
        if (player == null) continue;
        await player.setVolume(entry.value);
        _layers[index] = _layers[index].copyWith(isActive: true, volume: entry.value);
        await player.seek(Duration.zero);
        player.play();
        continue;
      }
      // Try custom audio
      if (_customPlayers.containsKey(entry.key)) {
        final player = _customPlayers[entry.key]!;
        await player.setVolume(entry.value);
        _customActive[entry.key] = true;
        _customVolume[entry.key] = entry.value;
        await player.seek(Duration.zero);
        player.play();
      }
      // else: audio was deleted — skip gracefully
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
    // Stop custom audio
    for (final id in _customActive.keys.toList()) {
      if (_customActive[id] == true) {
        _customActive[id] = false;
        await _customPlayers[id]?.pause();
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
    for (final id in _customActive.keys) {
      if (_customActive[id] == true) {
        final v = ((_customVolume[id] ?? 0.5) * factor).clamp(0.0, 1.0);
        _customVolume[id] = v;
        await _customPlayers[id]?.setVolume(v);
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
    for (final p in _customPlayers.values) {
      await p.dispose();
    }
    _customPlayers.clear();
  }
}
