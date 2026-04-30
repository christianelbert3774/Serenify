import 'dart:math';

/// Frequency modes berbasis riset brainwave entrainment
/// Setiap mode menggunakan carrier noise + binaural beat pada frekuensi target
enum FrequencyMode {
  /// Beta 14Hz — meningkatkan konsentrasi dan fokus
  /// Riset: Jirakittayakorn & Wongsawat (2017) — beta beats meningkatkan sustained attention
  focus,

  /// Alpha 10Hz — relaksasi sadar, menenangkan pikiran
  /// Riset: Foster (1990) — alpha entrainment mengurangi kecemasan
  relax,

  /// Delta 2Hz — deep sleep, pemulihan tubuh
  /// Riset: Jirakittayakorn & Wongsawat (2017) — delta beats meningkatkan kualitas tidur
  sleep,

  /// Theta 6Hz — meditasi mendalam, kreativitas
  /// Riset: Lavallee et al. (2011) — theta entrainment meningkatkan mindfulness
  meditate,
}

/// Parameter binaural per mode
class ModeParams {
  final double baseFreq;
  final double beatFreq;
  final double amplitude;
  final String label;
  final String subtitle;

  const ModeParams({
    required this.baseFreq,
    required this.beatFreq,
    required this.amplitude,
    required this.label,
    required this.subtitle,
  });
}

const Map<FrequencyMode, ModeParams> modeParams = {
  FrequencyMode.focus: ModeParams(
    baseFreq: 200, beatFreq: 14, amplitude: 0.40,
    label: 'Focus', subtitle: 'Beta 14Hz',
  ),
  FrequencyMode.relax: ModeParams(
    baseFreq: 180, beatFreq: 10, amplitude: 0.35,
    label: 'Relax', subtitle: 'Alpha 10Hz',
  ),
  FrequencyMode.sleep: ModeParams(
    baseFreq: 100, beatFreq: 2, amplitude: 0.30,
    label: 'Sleep', subtitle: 'Delta 2Hz',
  ),
  FrequencyMode.meditate: ModeParams(
    baseFreq: 150, beatFreq: 6, amplitude: 0.35,
    label: 'Meditate', subtitle: 'Theta 6Hz',
  ),
};

class NoiseGenerator {
  final Random _random = Random();

  // Phase trackers
  double _phaseL = 0.0;
  double _phaseR = 0.0;
  double _phaseHarmonicL = 0.0;
  double _phaseHarmonicR = 0.0;
  double _panPhase = 0.0; // LFO untuk stereo panning

  // Brown noise state (carrier)
  double _brownValue = 0.0;

  static const double _sampleRate = 44100.0;
  // LFO panning: 1 siklus penuh L→R→L setiap ~8 detik
  static const double _panLfoFreq = 0.125;

  /// Generate stereo interleaved samples [L, R, L, R, ...]
  /// Carrier = soft brown noise, overlaid dengan binaural beat sesuai mode
  /// Efek "cinema": stereo panning + harmonics + strong binaural presence
  List<double> generateStereoNoise(
    FrequencyMode mode,
    int sampleCount, {
    bool binauralEnabled = true,
  }) {
    final params = modeParams[mode]!;
    final stereo = List<double>.filled(sampleCount * 2, 0.0);

    for (int i = 0; i < sampleCount; i++) {
      // === Carrier: soft brown noise ===
      _brownValue += _random.nextDouble() * 0.16 - 0.08;
      _brownValue = _brownValue.clamp(-1.0, 1.0);
      final carrier = _brownValue * 0.5; // Keep carrier gentle

      // === Stereo panning LFO (flowing between ears) ===
      final panValue = sin(2 * pi * _panLfoFreq * _panPhase / _sampleRate);
      _panPhase += 1.0;
      if (_panPhase > _sampleRate / _panLfoFreq) _panPhase = 0;

      // Pan law: equal power panning
      final leftGain = cos((panValue + 1) * pi / 4);
      final rightGain = sin((panValue + 1) * pi / 4);

      double left = carrier * leftGain;
      double right = carrier * rightGain;

      if (binauralEnabled) {
        // === Fundamental binaural tones ===
        final toneL = params.amplitude *
            sin(2 * pi * params.baseFreq * _phaseL / _sampleRate);
        final toneR = params.amplitude *
            sin(2 * pi * (params.baseFreq + params.beatFreq) * _phaseR / _sampleRate);

        // === Harmonic (octave) for richness ===
        final harmonicL = (params.amplitude * 0.3) *
            sin(2 * pi * (params.baseFreq * 2) * _phaseHarmonicL / _sampleRate);
        final harmonicR = (params.amplitude * 0.3) *
            sin(2 * pi * ((params.baseFreq + params.beatFreq) * 2) * _phaseHarmonicR / _sampleRate);

        left += toneL + harmonicL;
        right += toneR + harmonicR;

        // Update phases
        _phaseL += 1.0;
        _phaseR += 1.0;
        _phaseHarmonicL += 1.0;
        _phaseHarmonicR += 1.0;

        // Prevent overflow
        if (_phaseL > _sampleRate) _phaseL -= _sampleRate;
        if (_phaseR > _sampleRate) _phaseR -= _sampleRate;
        if (_phaseHarmonicL > _sampleRate) _phaseHarmonicL -= _sampleRate;
        if (_phaseHarmonicR > _sampleRate) _phaseHarmonicR -= _sampleRate;
      }

      stereo[i * 2] = left.clamp(-1.0, 1.0);
      stereo[i * 2 + 1] = right.clamp(-1.0, 1.0);
    }

    return stereo;
  }

  /// Get pan value saat ini untuk sinkronisasi dengan soundscape panning
  double getCurrentPanValue() {
    return sin(2 * pi * _panLfoFreq * _panPhase / _sampleRate);
  }

  void resetPhases() {
    _phaseL = 0.0;
    _phaseR = 0.0;
    _phaseHarmonicL = 0.0;
    _phaseHarmonicR = 0.0;
    _panPhase = 0.0;
    _brownValue = 0.0;
  }
}
