import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/noise_generator.dart';
import '../../../providers/audio_provider.dart';

/// Frequency mode selector — Focus / Relax / Sleep / Meditate
class NoiseSelector extends ConsumerWidget {
  const NoiseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Frequency Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 2x2 grid of mode cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: FrequencyMode.values.map((mode) {
            final isActive = mixer.activeMode == mode;
            final params = modeParams[mode]!;
            return _ModeCard(
              mode: mode,
              label: params.label,
              subtitle: params.subtitle,
              icon: _iconForMode(mode),
              color: _colorForMode(mode),
              isActive: isActive,
              onTap: () {
                if (isActive) {
                  mixer.stopMode();
                } else {
                  mixer.playMode(mode);
                }
              },
            );
          }).toList(),
        ),

        // Volume slider (visible when mode is active)
        if (mixer.noiseIsPlaying) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.volume_down, size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              Expanded(
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    activeTrackColor: _colorForMode(mixer.activeMode!),
                    thumbColor: _colorForMode(mixer.activeMode!),
                  ),
                  child: Slider(
                    value: mixer.noiseVolume,
                    onChanged: (v) => mixer.setNoiseVolume(v),
                  ),
                ),
              ),
              Icon(Icons.volume_up, size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ],
    );
  }

  static IconData _iconForMode(FrequencyMode mode) {
    return switch (mode) {
      FrequencyMode.focus => Icons.psychology_outlined,
      FrequencyMode.relax => Icons.spa_outlined,
      FrequencyMode.sleep => Icons.bedtime_outlined,
      FrequencyMode.meditate => Icons.self_improvement_outlined,
    };
  }

  static Color _colorForMode(FrequencyMode mode) {
    return switch (mode) {
      FrequencyMode.focus => const Color(0xFF64B5F6),
      FrequencyMode.relax => const Color(0xFF81C784),
      FrequencyMode.sleep => const Color(0xFF9575CD),
      FrequencyMode.meditate => const Color(0xFFFFB74D),
    };
  }
}

class _ModeCard extends StatelessWidget {
  final FrequencyMode mode;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : theme.colorScheme.outline,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive ? color : null,
                      )),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      )),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
          ],
        ),
      ),
    );
  }
}
