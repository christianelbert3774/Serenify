import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_provider.dart';

/// List of soundscape layers — each row has icon, name, switch, + volume slider saat aktif
class SoundscapeGrid extends ConsumerWidget {
  const SoundscapeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch agar rebuild saat state berubah
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

        // List format
        ...layers.map((layer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(layer.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              layer.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: layer.isActive,
                            onChanged: (_) {
                              // Gunakan ref.read di callback, bukan ref.watch
                              ref.read(audioMixerProvider).toggleSoundscape(layer.id);
                            },
                          ),
                        ],
                      ),
                      // Volume slider — hanya muncul saat aktif
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: layer.isActive
                            ? Row(
                                children: [
                                  const SizedBox(width: 40),
                                  Expanded(
                                    child: Slider(
                                      value: layer.volume,
                                      onChanged: (v) {
                                        ref.read(audioMixerProvider)
                                            .setSoundscapeVolume(layer.id, v);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${(layer.volume * 100).round()}%',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
