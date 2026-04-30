import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/timer_provider.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  static const _quickDurations = [5, 15, 25, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final state = timer.state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.isRunning
            ? _buildActiveTimer(context, ref, state, theme)
            : _buildTimerSetup(context, ref, theme),
      ),
    );
  }

  Widget _buildTimerSetup(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.timer_outlined,
            size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        Text('Set Timer',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Audio will fade out and stop after the selected duration',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),

        // Quick select chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _quickDurations.map((min) {
            return ActionChip(
              label: Text('$min min'),
              onPressed: () {
                ref.read(timerProvider).startTimer(Duration(minutes: min));
              },
              side: BorderSide(color: theme.colorScheme.outline),
              backgroundColor: theme.colorScheme.surface,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Custom timer button
        OutlinedButton.icon(
          onPressed: () => _showCustomTimerDialog(context, ref),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Custom Duration'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 24),

        // Fade out info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.volume_off_outlined, size: 20,
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

  Widget _buildActiveTimer(
      BuildContext context, WidgetRef ref, TimerState state, ThemeData theme) {
    final isFading = state.remaining <= const Duration(seconds: 30);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                  Text(
                    state.remainingText,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
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

  void _showCustomTimerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Timer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Duration in minutes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
    );
  }
}
