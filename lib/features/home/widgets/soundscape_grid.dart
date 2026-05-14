import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_provider.dart';

/// List of soundscape layers — each row has icon, name, switch, + volume slider saat aktif
class SoundscapeGrid extends ConsumerWidget {
  const SoundscapeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);
    final layers = mixer.layers;
    final customAudios = mixer.customAudios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
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
              // "Get more sound" — opens custom dialog
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _GetMoreSoundDialog(ref: ref),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Get more sound',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (layers.any((l) => l.isActive) ||
                  customAudios.any((a) => mixer.isCustomActive(a.id)))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activeCount(mixer)} active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Built-in soundscapes ──
        ...layers.map((layer) => _SoundscapeTile(layer: layer)),

        // ── Custom audio section ──
        if (customAudios.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
            child: Text(
              'Imported Audio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...customAudios.map((audio) => _CustomAudioTile(audio: audio)),
        ],
      ],
    );
  }

  int _activeCount(AudioMixerNotifier mixer) {
    int count = mixer.layers.where((l) => l.isActive).length;
    for (final a in mixer.customAudios) {
      if (mixer.isCustomActive(a.id)) count++;
    }
    return count;
  }
}

// =============================================================================
//  "Get More Sound" Dialog — centered, left tabs + right content
// =============================================================================

class _GetMoreSoundDialog extends StatefulWidget {
  final WidgetRef ref;
  const _GetMoreSoundDialog({required this.ref});

  @override
  State<_GetMoreSoundDialog> createState() => _GetMoreSoundDialogState();
}

class _GetMoreSoundDialogState extends State<_GetMoreSoundDialog> {
  int _selectedIndex = 0;
  bool _importing = false;

  static const _menuItems = [
    (icon: Icons.upload_file_outlined, label: 'Import Audio'),
    (icon: Icons.download_outlined, label: 'Download'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        height: 300,
        child: Row(
          children: [
            // ── Left menu panel ──
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.primary.withValues(alpha: 0.06),
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Icon + title
                  Image.asset('assets/image/applogocream.png',
                      width: 80),
                  const SizedBox(height: 14),
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  const SizedBox(height: 8),
                  // Menu items
                  ...List.generate(_menuItems.length, (i) {
                    final item = _menuItems[i];
                    final selected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Material(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                Icon(item.icon,
                                    size: 16,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(item.label,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Close button
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Close',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right content panel ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _selectedIndex == 0
                    ? _importContent(theme)
                    : _downloadContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Import Audio content ──
  Widget _importContent(ThemeData theme) {
    return Padding(
      key: const ValueKey('import'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Audio',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            'Import audio files from your device. '
            'Supported formats: MP3, WAV, OGG, M4A, FLAC.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Format chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['MP3', 'WAV', 'OGG', 'M4A', 'FLAC'].map((fmt) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(fmt,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    )),
              );
            }).toList(),
          ),
          const Spacer(),
          // Import button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _importing
                  ? null
                  : () async {
                      setState(() => _importing = true);
                      await widget.ref
                          .read(audioMixerProvider)
                          .importCustomAudio();
                      if (mounted) {
                        setState(() => _importing = false);
                        Navigator.pop(context);
                      }
                    },
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(_importing ? 'Importing...' : 'Browse Files'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Download Soundscape content ──
  Widget _downloadContent(ThemeData theme) {
    return Padding(
      key: const ValueKey('download'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Download Soundscape',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            'Download additional soundscape packs directly '
            'to your device from the Serenify library.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const Spacer(),
          // Coming soon banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Coming soon in a future update.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  Built-in Soundscape Tile
// =============================================================================

class _SoundscapeTile extends ConsumerWidget {
  final dynamic layer;
  const _SoundscapeTile({required this.layer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
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
                      ref.read(audioMixerProvider).toggleSoundscape(layer.id);
                    },
                  ),
                ],
              ),
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
                                ref
                                    .read(audioMixerProvider)
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
    );
  }
}

// =============================================================================
//  Custom Audio Tile
// =============================================================================

class _CustomAudioTile extends ConsumerWidget {
  final dynamic audio;
  const _CustomAudioTile({required this.audio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mixer = ref.watch(audioMixerProvider);
    final isActive = mixer.isCustomActive(audio.id);
    final volume = mixer.customVolume(audio.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('custom_${audio.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Audio'),
            content: Text('Delete "${audio.name}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        ),
        onDismissed: (_) {
          ref.read(audioMixerProvider).deleteCustomAudio(audio);
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.audio_file,
                        size: 18,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        audio.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (_) {
                        ref
                            .read(audioMixerProvider)
                            .toggleCustomAudio(audio.id);
                      },
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: isActive
                      ? Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Slider(
                                value: volume,
                                onChanged: (v) {
                                  ref
                                      .read(audioMixerProvider)
                                      .setCustomVolume(audio.id, v);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${(volume * 100).round()}%',
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
      ),
    );
  }
}
