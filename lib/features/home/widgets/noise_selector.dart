import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_mixer.dart';
import '../../../providers/audio_provider.dart';
import '../../../shared/theme/app_theme.dart';

/// Horizontal noise type selector cards — White / Pink / Brown
class NoiseSelector extends ConsumerWidget {
  const NoiseSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Noise Generator',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Noise type cards
        Row(
          children: NoiseType.values.map((type) {
            final isActive = mixer.activeNoiseType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _NoiseCard(
                  type: type,
                  isActive: isActive,
                  onTap: () {
                    if (isActive) {
                      mixer.stopNoise();
                    } else {
                      mixer.playNoise(type);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),

        // Volume slider (visible saat ada noise aktif)
        if (mixer.noiseIsPlaying) ...[
          const SizedBox(height: 12),
          _NoiseVolumeSlider(
            volume: mixer.noiseVolume,
            activeColor: _colorForType(mixer.activeNoiseType!),
            onChanged: (v) => mixer.setNoiseVolume(v),
          ),
        ],
      ],
    );
  }

  static Color _colorForType(NoiseType type) {
    return switch (type) {
      NoiseType.white => AppTheme.noiseWhite,
      NoiseType.pink => AppTheme.noisePink,
      NoiseType.brown => AppTheme.noiseBrown,
    };
  }
}

/// Individual noise card with animated active state
class _NoiseCard extends StatelessWidget {
  final NoiseType type;
  final bool isActive;
  final VoidCallback onTap;

  const _NoiseCard({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForType(type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : theme.colorScheme.outline,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            // Animated indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.transparent,
                border: Border.all(
                  color: isActive ? color : theme.colorScheme.outline,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _label(type),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? color : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle(type),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorForType(NoiseType type) {
    return switch (type) {
      NoiseType.white => AppTheme.noiseWhite,
      NoiseType.pink => AppTheme.noisePink,
      NoiseType.brown => AppTheme.noiseBrown,
    };
  }

  static String _label(NoiseType type) {
    return switch (type) {
      NoiseType.white => 'White',
      NoiseType.pink => 'Pink',
      NoiseType.brown => 'Brown',
    };
  }

  static String _subtitle(NoiseType type) {
    return switch (type) {
      NoiseType.white => 'All frequencies',
      NoiseType.pink => 'Deep & warm',
      NoiseType.brown => 'Ultra deep',
    };
  }
}

/// Noise volume slider row
class _NoiseVolumeSlider extends StatelessWidget {
  final double volume;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _NoiseVolumeSlider({
    required this.volume,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.volume_down, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        Expanded(
          child: SliderTheme(
            data: theme.sliderTheme.copyWith(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
            ),
            child: Slider(value: volume, onChanged: onChanged),
          ),
        ),
        Icon(Icons.volume_up, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      ],
    );
  }
}
