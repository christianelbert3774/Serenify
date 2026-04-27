import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/soundscape_layer.dart';
import '../../../providers/audio_provider.dart';

/// Grid of soundscape layers — each tile has toggle + volume slider
class SoundscapeGrid extends ConsumerWidget {
  const SoundscapeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);
    final layers = mixer.layers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                'Soundscapes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Active count badge
              if (layers.any((l) => l.isActive))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${layers.where((l) => l.isActive).length} active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Grid 2 columns
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: layers.length,
          itemBuilder: (context, index) {
            return _SoundscapeTile(layer: layers[index]);
          },
        ),
      ],
    );
  }
}

/// Individual soundscape tile with animated active state
class _SoundscapeTile extends ConsumerWidget {
  final SoundscapeLayer layer;

  const _SoundscapeTile({required this.layer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.read(audioMixerProvider);
    final theme = Theme.of(context);
    final isActive = layer.isActive;

    return GestureDetector(
      onTap: () => mixer.toggleSoundscape(layer.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + name + indicator
            Row(
              children: [
                Text(layer.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    layer.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Active indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? theme.colorScheme.primary : Colors.transparent,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Volume slider (only when active)
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: isActive
                  ? Column(
                      children: [
                        SliderTheme(
                          data: theme.sliderTheme.copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: layer.volume,
                            onChanged: (v) => mixer.setSoundscapeVolume(layer.id, v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(layer.volume * 100).round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => mixer.toggleSoundscape(layer.id),
                                child: Icon(
                                  Icons.stop_circle_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(
                      height: 40,
                      child: Center(
                        child: Text('Tap to play', style: TextStyle(fontSize: 12)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
