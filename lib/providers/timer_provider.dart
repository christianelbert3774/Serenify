import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_provider.dart';

// =============================================================================
//  STANDARD TIMER
// =============================================================================

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

// =============================================================================
//  POMODORO TIMER
// =============================================================================

/// Flow per cycle:
///   Work → SB → Work → SB → Work → SB → Work → LB
///   (4 work sessions, 3 short breaks, 1 long break)
///
/// After long break → STOP (one full pomodoro set is done).

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroConfig {
  final Duration workDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int workSessionsPerCycle; // default 4 — how many focus blocks before long break
  final String? workPresetName;
  final String? shortBreakPresetName;
  final String? longBreakPresetName;

  const PomodoroConfig({
    this.workDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.workSessionsPerCycle = 4,
    this.workPresetName,
    this.shortBreakPresetName,
    this.longBreakPresetName,
  });

  PomodoroConfig copyWith({
    Duration? workDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? workSessionsPerCycle,
    String? Function()? workPresetName,
    String? Function()? shortBreakPresetName,
    String? Function()? longBreakPresetName,
  }) {
    return PomodoroConfig(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      workSessionsPerCycle: workSessionsPerCycle ?? this.workSessionsPerCycle,
      workPresetName: workPresetName != null ? workPresetName() : this.workPresetName,
      shortBreakPresetName: shortBreakPresetName != null ? shortBreakPresetName() : this.shortBreakPresetName,
      longBreakPresetName: longBreakPresetName != null ? longBreakPresetName() : this.longBreakPresetName,
    );
  }
}

class PomodoroState {
  final PomodoroPhase currentPhase;
  final int currentWork;          // which work session we're on (1-based)
  final int totalWorkSessions;    // = workSessionsPerCycle (e.g. 4)
  final Duration remaining;
  final Duration totalForPhase;
  final bool isRunning;
  final bool isComplete;          // true when full pomodoro set is done
  final PomodoroConfig config;

  const PomodoroState({
    this.currentPhase = PomodoroPhase.work,
    this.currentWork = 1,
    this.totalWorkSessions = 4,
    this.remaining = Duration.zero,
    this.totalForPhase = Duration.zero,
    this.isRunning = false,
    this.isComplete = false,
    this.config = const PomodoroConfig(),
  });

  double get progress =>
      totalForPhase.inSeconds > 0
          ? remaining.inSeconds / totalForPhase.inSeconds
          : 0.0;

  String get remainingText {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get phaseLabel => switch (currentPhase) {
    PomodoroPhase.work => 'Focus Time',
    PomodoroPhase.shortBreak => 'Short Break',
    PomodoroPhase.longBreak => 'Long Break',
  };

  PomodoroState copyWith({
    PomodoroPhase? currentPhase,
    int? currentWork,
    int? totalWorkSessions,
    Duration? remaining,
    Duration? totalForPhase,
    bool? isRunning,
    bool? isComplete,
    PomodoroConfig? config,
  }) {
    return PomodoroState(
      currentPhase: currentPhase ?? this.currentPhase,
      currentWork: currentWork ?? this.currentWork,
      totalWorkSessions: totalWorkSessions ?? this.totalWorkSessions,
      remaining: remaining ?? this.remaining,
      totalForPhase: totalForPhase ?? this.totalForPhase,
      isRunning: isRunning ?? this.isRunning,
      isComplete: isComplete ?? this.isComplete,
      config: config ?? this.config,
    );
  }
}

class PomodoroNotifier extends ChangeNotifier {
  final Ref _ref;
  Timer? _timer;
  PomodoroState _state = const PomodoroState();

  PomodoroNotifier(this._ref);

  PomodoroState get state => _state;

  /// Start pomodoro — begins with Work session 1.
  void start(PomodoroConfig config) {
    cancel();
    _state = PomodoroState(
      currentPhase: PomodoroPhase.work,
      currentWork: 1,
      totalWorkSessions: config.workSessionsPerCycle,
      remaining: config.workDuration,
      totalForPhase: config.workDuration,
      isRunning: true,
      isComplete: false,
      config: config,
    );
    _applyAudioForPhase();
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_state.remaining.inSeconds <= 0) {
      _nextPhase();
      return;
    }
    _state = _state.copyWith(
      remaining: _state.remaining - const Duration(seconds: 1),
    );
    notifyListeners();
  }

  /// Phase transition logic:
  ///
  /// Work 1 → Short Break
  /// Short Break → Work 2
  /// Work 2 → Short Break
  /// Short Break → Work 3
  /// Work 3 → Short Break
  /// Short Break → Work 4 (last)
  /// Work 4 → Long Break
  /// Long Break → STOP
  void _nextPhase() {
    final config = _state.config;

    switch (_state.currentPhase) {
      case PomodoroPhase.work:
        if (_state.currentWork >= config.workSessionsPerCycle) {
          // Last work session done → Long Break
          _goToPhase(PomodoroPhase.longBreak, config.longBreakDuration);
        } else {
          // Not last work → Short Break
          _goToPhase(PomodoroPhase.shortBreak, config.shortBreakDuration);
        }

      case PomodoroPhase.shortBreak:
        // After short break → next Work session
        _state = _state.copyWith(
          currentWork: _state.currentWork + 1,
        );
        _goToPhase(PomodoroPhase.work, config.workDuration);

      case PomodoroPhase.longBreak:
        // Long break done → Pomodoro complete, STOP
        _onComplete();
    }
  }

  void _goToPhase(PomodoroPhase phase, Duration duration) {
    _state = _state.copyWith(
      currentPhase: phase,
      remaining: duration,
      totalForPhase: duration,
    );
    _applyAudioForPhase();
    notifyListeners();
  }

  void _onComplete() {
    _timer?.cancel();
    _timer = null;
    _ref.read(audioMixerProvider).stopAll();
    _state = _state.copyWith(
      isRunning: false,
      isComplete: true,
      remaining: Duration.zero,
    );
    notifyListeners();
  }

  void _applyAudioForPhase() {
    final mixer = _ref.read(audioMixerProvider);
    final presets = _ref.read(presetsProvider);

    String? presetName;
    switch (_state.currentPhase) {
      case PomodoroPhase.work:
        presetName = _state.config.workPresetName;
      case PomodoroPhase.shortBreak:
        presetName = _state.config.shortBreakPresetName;
      case PomodoroPhase.longBreak:
        presetName = _state.config.longBreakPresetName;
    }

    if (presetName != null && presets.isNotEmpty) {
      try {
        final preset = presets.firstWhere((p) => p.name == presetName);
        mixer.applyPreset(preset);
      } catch (_) {
        // Preset was deleted — stop audio
        mixer.stopAll();
      }
    } else {
      mixer.stopAll();
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _state = const PomodoroState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = ChangeNotifierProvider<PomodoroNotifier>((ref) {
  return PomodoroNotifier(ref);
});


