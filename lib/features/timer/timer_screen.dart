import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/timer_provider.dart';
import '../../providers/audio_provider.dart';
import '../../core/models/preset.dart';

// =============================================================================
//  Timer mode enum for SegmentedButton
// =============================================================================

enum _TimerMode { standard, pomodoro }

// =============================================================================
//  Timer Screen
// =============================================================================

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  _TimerMode _mode = _TimerMode.standard;

  // Pomodoro config (editable in setup)
  int _workMin = 25;
  int _shortBreakMin = 5;
  int _longBreakMin = 15;
  int _cycles = 4;
  String? _workPreset;
  String? _shortBreakPreset;
  String? _longBreakPreset;

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final pomo = ref.watch(pomodoroProvider);
    final isAnyRunning = timer.state.isRunning || pomo.state.isRunning;

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Segment toggle (disabled while running)
            SegmentedButton<_TimerMode>(
              segments: const [
                ButtonSegment(
                  value: _TimerMode.standard,
                  label: Text('Standard'),
                  icon: Icon(Icons.timer_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _TimerMode.pomodoro,
                  label: Text('Pomodoro'),
                  icon: Icon(Icons.local_fire_department_outlined, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: isAnyRunning
                  ? null
                  : (set) => setState(() => _mode = set.first),
            ),
            const SizedBox(height: 24),

            // Content
            if (_mode == _TimerMode.standard)
              timer.state.isRunning
                  ? _StandardActive(state: timer.state)
                  : const _StandardSetup()
            else
              pomo.state.isRunning || pomo.state.isComplete
                  ? _PomodoroActive(state: pomo.state)
                  : _PomodoroSetup(
                      workMin: _workMin,
                      shortBreakMin: _shortBreakMin,
                      longBreakMin: _longBreakMin,
                      cycles: _cycles,
                      workPreset: _workPreset,
                      shortBreakPreset: _shortBreakPreset,
                      longBreakPreset: _longBreakPreset,
                      onWorkMinChanged: (v) => setState(() => _workMin = v),
                      onShortBreakMinChanged: (v) => setState(() => _shortBreakMin = v),
                      onLongBreakMinChanged: (v) => setState(() => _longBreakMin = v),
                      onCyclesChanged: (v) => setState(() => _cycles = v),
                      onWorkPresetChanged: (v) => setState(() => _workPreset = v),
                      onShortBreakPresetChanged: (v) => setState(() => _shortBreakPreset = v),
                      onLongBreakPresetChanged: (v) => setState(() => _longBreakPreset = v),
                      onStart: _startPomodoro,
                    ),
          ],
        ),
      ),
    );
  }

  void _startPomodoro() {
    ref.read(pomodoroProvider).start(PomodoroConfig(
      workDuration: Duration(minutes: _workMin),
      shortBreakDuration: Duration(minutes: _shortBreakMin),
      longBreakDuration: Duration(minutes: _longBreakMin),
      workSessionsPerCycle: _cycles,
      workPresetName: _workPreset,
      shortBreakPresetName: _shortBreakPreset,
      longBreakPresetName: _longBreakPreset,
    ));
  }
}

// =============================================================================
//  STANDARD TIMER — Setup
// =============================================================================

class _StandardSetup extends ConsumerWidget {
  const _StandardSetup();

  static const _quickDurations = [5, 15, 25, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(Icons.timer_outlined,
            size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        Text('Set Timer',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Audio will fade out and stop after the selected duration',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _quickDurations.map((min) {
            return ActionChip(
              label: Text('$min min'),
              onPressed: () =>
                  ref.read(timerProvider).startTimer(Duration(minutes: min)),
              side: BorderSide(color: theme.colorScheme.outline),
              backgroundColor: theme.colorScheme.surface,
              labelStyle:
                  theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () => _showCustomDialog(context, ref),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Custom Duration'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.volume_off_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Volume will gradually fade out in the last 30 seconds',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Custom Timer',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Duration in minutes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final minutes = int.tryParse(controller.text.trim());
                    if (minutes == null || minutes <= 0) return;
                    ref.read(timerProvider).startTimer(Duration(minutes: minutes));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  STANDARD TIMER — Active
// =============================================================================

class _StandardActive extends ConsumerWidget {
  final TimerState state;
  const _StandardActive({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFading = state.remaining <= const Duration(seconds: 30);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    isFading ? Colors.orange : theme.colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.remainingText,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      )),
                  if (isFading)
                    Text('Fading out...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => ref.read(timerProvider).cancelTimer(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel Timer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
//  POMODORO — Setup
// =============================================================================

class _PomodoroSetup extends ConsumerWidget {
  final int workMin, shortBreakMin, longBreakMin, cycles;
  final String? workPreset, shortBreakPreset, longBreakPreset;
  final ValueChanged<int> onWorkMinChanged, onShortBreakMinChanged,
      onLongBreakMinChanged, onCyclesChanged;
  final ValueChanged<String?> onWorkPresetChanged, onShortBreakPresetChanged,
      onLongBreakPresetChanged;
  final VoidCallback onStart;

  const _PomodoroSetup({
    required this.workMin,
    required this.shortBreakMin,
    required this.longBreakMin,
    required this.cycles,
    required this.workPreset,
    required this.shortBreakPreset,
    required this.longBreakPreset,
    required this.onWorkMinChanged,
    required this.onShortBreakMinChanged,
    required this.onLongBreakMinChanged,
    required this.onCyclesChanged,
    required this.onWorkPresetChanged,
    required this.onShortBreakPresetChanged,
    required this.onLongBreakPresetChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final presets = ref.watch(presetsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon + title
        Icon(Icons.local_fire_department_outlined,
            size: 56, color: Colors.deepOrange.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Center(
          child: Text('Pomodoro Timer',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),

        // Duration config
        Text('Duration',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _DurationRow(
                  label: 'Work',
                  icon: Icons.adjust,
                  value: workMin,
                  onChanged: onWorkMinChanged,
                ),
                const Divider(height: 1),
                _DurationRow(
                  label: 'Short Break',
                  icon: Icons.coffee_outlined,
                  value: shortBreakMin,
                  onChanged: onShortBreakMinChanged,
                ),
                const Divider(height: 1),
                _DurationRow(
                  label: 'Long Break',
                  icon: Icons.nightlight_outlined,
                  value: longBreakMin,
                  onChanged: onLongBreakMinChanged,
                ),
                const Divider(height: 1),
                _DurationRow(
                  label: 'Cycles',
                  icon: Icons.repeat,
                  value: cycles,
                  onChanged: onCyclesChanged,
                  suffix: '',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Audio per phase
        Text('Audio per Phase',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Select a preset to auto-play during each phase',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _PresetSelector(
                  label: '🎯  Work',
                  value: workPreset,
                  presets: presets,
                  onChanged: onWorkPresetChanged,
                ),
                const SizedBox(height: 12),
                _PresetSelector(
                  label: '☕  Short Break',
                  value: shortBreakPreset,
                  presets: presets,
                  onChanged: onShortBreakPresetChanged,
                ),
                const SizedBox(height: 12),
                _PresetSelector(
                  label: '🌙  Long Break',
                  value: longBreakPreset,
                  presets: presets,
                  onChanged: onLongBreakPresetChanged,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Start button
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Pomodoro'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
//  POMODORO — Active
// =============================================================================

class _PomodoroActive extends ConsumerWidget {
  final PomodoroState state;
  const _PomodoroActive({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Completed state
    if (state.isComplete) {
      return Column(
        children: [
          const SizedBox(height: 48),
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Pomodoro Complete!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 8),
          Text('Great focus session!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ref.read(pomodoroProvider).cancel(),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    // Running state
    final phaseColor = _colorForPhase(state.currentPhase);

    return Column(
      children: [
        const SizedBox(height: 16),

        // Phase label + cycle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_iconForPhase(state.currentPhase),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(state.phaseLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: phaseColor,
                )),
          ],
        ),
        const SizedBox(height: 4),
        Text('Focus ${state.currentWork}/${state.totalWorkSessions}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),

        const SizedBox(height: 32),

        // Circular progress
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(phaseColor),
                ),
              ),
              Text(state.remainingText,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Cycle dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(state.totalWorkSessions, (i) {
            final filled = i < state.currentWork;
            final isCurrent = i == state.currentWork - 1 &&
                state.currentPhase == PomodoroPhase.work;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? phaseColor
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                border: isCurrent
                    ? Border.all(color: phaseColor, width: 2)
                    : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 40),

        // Stop button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(pomodoroProvider).cancel();
              ref.read(audioMixerProvider).stopAll();
            },
            icon: const Icon(Icons.stop),
            label: const Text('Stop Pomodoro'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Color _colorForPhase(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.work => const Color(0xFF42A5F5),
    PomodoroPhase.shortBreak => const Color(0xFF81C784),
    PomodoroPhase.longBreak => const Color(0xFFFFB74D),
  };

  String _iconForPhase(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.work => '🎯',
    PomodoroPhase.shortBreak => '☕',
    PomodoroPhase.longBreak => '🌙',
  };
}

// =============================================================================
//  Helper Widgets
// =============================================================================

/// Editable duration row with +/- buttons
class _DurationRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;

  const _DurationRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.suffix = 'min',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
          // Minus
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 40,
            child: Text(
              suffix.isEmpty ? '$value' : '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Plus
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: () => onChanged(value + 1),
            visualDensity: VisualDensity.compact,
          ),
          if (suffix.isNotEmpty)
            SizedBox(
              width: 28,
              child: Text(suffix,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
            ),
        ],
      ),
    );
  }
}

/// Dropdown to pick a preset for a pomodoro phase
class _PresetSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<Preset> presets;
  final ValueChanged<String?> onChanged;

  const _PresetSelector({
    required this.label,
    required this.value,
    required this.presets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None (silence)',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              ...presets.map((p) => DropdownMenuItem<String?>(
                    value: p.name,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
