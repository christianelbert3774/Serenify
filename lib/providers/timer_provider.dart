import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_provider.dart';

class TimerState {
  final Duration totalDuration;
  final Duration remaining;
  final bool isRunning;

  const TimerState({
    this.totalDuration = Duration.zero,
    this.remaining = Duration.zero,
    this.isRunning = false,
  });

  double get progress =>
      totalDuration.inSeconds > 0
          ? remaining.inSeconds / totalDuration.inSeconds
          : 0.0;

  String get remainingText {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (remaining.inHours > 0) {
      return '${remaining.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  TimerState copyWith({
    Duration? totalDuration,
    Duration? remaining,
    bool? isRunning,
  }) {
    return TimerState(
      totalDuration: totalDuration ?? this.totalDuration,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

/// Timer notifier — countdown with always-on fade out (last 30 seconds)
class TimerNotifier extends ChangeNotifier {
  final Ref _ref;
  Timer? _timer;
  TimerState _state = const TimerState();

  static const Duration _fadeDuration = Duration(seconds: 30);

  TimerNotifier(this._ref);

  TimerState get state => _state;

  void startTimer(Duration duration) {
    cancelTimer();
    _state = TimerState(
      totalDuration: duration,
      remaining: duration,
      isRunning: true,
    );
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_state.remaining.inSeconds <= 0) {
      _onTimerComplete();
      return;
    }

    _state = _state.copyWith(
      remaining: _state.remaining - const Duration(seconds: 1),
    );

    // Always fade out in last 30 seconds
    if (_state.remaining <= _fadeDuration) {
      final fadeProgress = _state.remaining.inSeconds / _fadeDuration.inSeconds;
      if (_state.remaining.inSeconds % 3 == 0) {
        _ref.read(audioMixerProvider).setMasterVolume(fadeProgress.clamp(0.0, 1.0));
      }
    }

    notifyListeners();
  }

  void _onTimerComplete() {
    _ref.read(audioMixerProvider).stopAll();
    cancelTimer();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _state = const TimerState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = ChangeNotifierProvider<TimerNotifier>((ref) {
  return TimerNotifier(ref);
});
