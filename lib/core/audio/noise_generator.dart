import 'dart:math';

enum FrequencyMode { focus, relax, sleep, meditate }

class ModeParams {
  final String label;
  final String subtitle;
  const ModeParams({required this.label, required this.subtitle});
}

const Map<FrequencyMode, ModeParams> modeParams = {
  FrequencyMode.focus:    ModeParams(label: 'Focus',    subtitle: 'Beta 14Hz'),
  FrequencyMode.relax:    ModeParams(label: 'Relax',    subtitle: 'Alpha 10Hz'),
  FrequencyMode.sleep:    ModeParams(label: 'Sleep',    subtitle: 'Delta 2Hz'),
  FrequencyMode.meditate: ModeParams(label: 'Meditate', subtitle: 'Theta 6Hz'),
};

/// Stereo brown noise with slow LFO panning.
/// No binaural beats — just_audio already outputs soundscapes in stereo natively.
class NoiseGenerator {
  final Random _random = Random();
  double _brown = 0.0;
  double _panPhase = 0.0;

  static const double _sr = 44100.0;
  static const double _panHz = 0.125; // full L→R→L every ~8s

  /// Returns interleaved stereo samples [L, R, L, R, ...]
  List<double> generateStereo(FrequencyMode mode, int count) {
    final out = List<double>.filled(count * 2, 0.0);
    for (int i = 0; i < count; i++) {
      _brown += _random.nextDouble() * 0.16 - 0.08;
      _brown = _brown.clamp(-1.0, 1.0);
      final carrier = _brown * 0.65;

      final pan = sin(2 * pi * _panHz * _panPhase / _sr);
      _panPhase = (_panPhase + 1.0) % (_sr / _panHz);

      // Equal-power pan law
      final l = cos((pan + 1) * pi / 4);
      final r = sin((pan + 1) * pi / 4);

      out[i * 2]     = (carrier * l).clamp(-1.0, 1.0);
      out[i * 2 + 1] = (carrier * r).clamp(-1.0, 1.0);
    }
    return out;
  }

  void reset() {
    _brown = 0.0;
    _panPhase = 0.0;
  }
}
