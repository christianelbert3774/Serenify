import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/preset.dart';
import '../../core/storage/preset_repository.dart';
import '../../providers/audio_provider.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider);
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Presets')),
      body: presets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No presets yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 8),
                  Text('Set up your ideal mix, then save it here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      )),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isThisActive = mixer.activePresetName == preset.name;
                return _PresetTile(
                  preset: preset,
                  isActive: isThisActive,
                  isPaused: isThisActive && mixer.isPaused,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSaveDialog(context, ref),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Current'),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Preset name...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final mixer = ref.read(audioMixerProvider);
              final preset = mixer.capturePreset(name);
              await PresetRepository.savePreset(preset);
              ref.read(presetsProvider.notifier).state =
                  PresetRepository.getPresets();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends ConsumerWidget {
  final Preset preset;
  final bool isActive;
  final bool isPaused;

  const _PresetTile({
    required this.preset,
    required this.isActive,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(preset.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await PresetRepository.deletePreset(preset);
        ref.read(presetsProvider.notifier).state = PresetRepository.getPresets();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.music_note : Icons.music_note_outlined,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(preset.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? theme.colorScheme.primary : null,
              )),
          subtitle: Text(
            _buildSubtitle(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          // Play/Pause button — icon changes based on state
          trailing: IconButton(
            icon: Icon(
              isActive && !isPaused
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              size: 36,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: () async {
              final mixer = ref.read(audioMixerProvider);
              if (isActive) {
                // Toggle pause/resume
                await mixer.togglePause();
              } else {
                // Apply this preset
                await mixer.applyPreset(preset);
              }
            },
          ),
          onTap: () async {
            final mixer = ref.read(audioMixerProvider);
            if (isActive) {
              await mixer.togglePause();
            } else {
              await mixer.applyPreset(preset);
            }
          },
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (preset.noiseType != null) parts.add(preset.noiseType!);
    if (preset.activeSoundscapes.isNotEmpty) {
      parts.add('${preset.activeSoundscapes.length} soundscape(s)');
    }
    if (preset.binauralEnabled) parts.add('binaural');
    if (parts.isEmpty) parts.add('Empty preset');
    return parts.join(' · ');
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Delete "${preset.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
  }
}
