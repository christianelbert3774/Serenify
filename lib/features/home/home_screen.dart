import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../core/audio/audio_session_manager.dart';
import '../../features/credits/credits_screen.dart';
import 'widgets/noise_selector.dart';
import 'widgets/soundscape_grid.dart';

/// HomeScreen — layar utama Serenify
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final mixer = ref.read(audioMixerProvider);
    await mixer.init();

    // Setup audio session
    await AudioSessionManager.init(
      onPause: () => mixer.stopAll(),
      onResume: () {},
      onDuck: (volume) => mixer.setNoiseVolume(volume * 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mixer = ref.watch(audioMixerProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    if (!mixer.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Preparing audio...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/image/applogocream.png', width: 130),
        actions: [
          // Info button
          IconButton(
            icon: Icon(Icons.info_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Info',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _InfoDialog(),
            ),
          ),
          // Theme toggle
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // Noise selector
            const NoiseSelector(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Soundscape grid
            const SoundscapeGrid(),

            const SizedBox(height: 24),

            // Stop all button
            _buildStopAllButton(theme, mixer),
          ],
        ),
      ),
    );
  }

  Widget _buildStopAllButton(ThemeData theme, AudioMixerNotifier mixer) {
    return Column(
      children: [
        // Pause / Resume button
        if (mixer.hasAnyActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => mixer.togglePause(),
                icon: Icon(
                  mixer.isPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                ),
                label: Text(mixer.isPaused ? 'Resume' : 'Pause'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

        // Stop all button
        SizedBox(
          width: double.infinity,
          child: AnimatedOpacity(
            opacity: mixer.hasAnyActive ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: mixer.hasAnyActive ? () => mixer.stopAll() : null,
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              label: const Text('Stop All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
//  Info Dialog — centered dialog with left tabs + right content
// =============================================================================

class _InfoDialog extends StatefulWidget {
  const _InfoDialog();

  @override
  State<_InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<_InfoDialog> {
  int _selectedIndex = 0;

  static const _menuItems = [
    (icon: Icons.info_outline, label: 'About'),
    (icon: Icons.verified_outlined, label: 'Version'),
    (icon: Icons.description_outlined, label: 'Credits'),
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
              width: 110,
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
                  const SizedBox(height: 16),
                  // Logo
                  Image.asset('assets/image/applogocream.png',
                      width: 80),
                  const SizedBox(height: 16),
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
                  // Close button at bottom
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
                        child: const Text('Close', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right content panel ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return switch (_selectedIndex) {
      0 => _aboutContent(theme),
      1 => _versionContent(theme),
      2 => _creditsContent(theme),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _aboutContent(ThemeData theme) {
    return Padding(
      key: const ValueKey('about'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Text(
            'Serenify is an offline noise & ambient '
            'soundscape generator for Android.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          Text('Built by Christian Elbert',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const SizedBox(height: 2),
          Text('Teknik Informatika — Universitas Riau',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _versionContent(ThemeData theme) {
    return Padding(
      key: const ValueKey('version'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _versionRow(theme, 'App Version', '1.0.0'),
          _versionRow(theme, 'Build', '1'),
          _versionRow(theme, 'Platform', 'Android'),
          _versionRow(theme, 'Framework', 'Flutter'),
          _versionRow(theme, 'Language', 'Dart'),
        ],
      ),
    );
  }

  Widget _versionRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                )),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _creditsContent(ThemeData theme) {
    return Padding(
      key: const ValueKey('credits'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Credits',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              // "View all" to full page
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreditsScreen()));
                },
                child: Text('View all →',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                _CreditMini(icon: '🌧️', name: 'Rain Umbrella', license: 'CC BY 4.0'),
                _CreditMini(icon: '🌊', name: 'Beach Waves', license: 'CC0'),
                _CreditMini(icon: '🫧', name: 'Bubble', license: 'CC0'),
                _CreditMini(icon: '🎵', name: 'Lo-Fi', license: 'CC0'),
                _CreditMini(icon: '🎹', name: 'Piano', license: 'CC0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditMini extends StatelessWidget {
  final String icon, name, license;
  const _CreditMini({
    required this.icon,
    required this.name,
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(license,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
