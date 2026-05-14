import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _credits = [
    _CreditItem(
      icon: '🌧️',
      name: 'Rain Umbrella',
      source: 'Freesound.org',
      creator: 'InspectorJ',
      license: 'CC BY 4.0',
    ),
    _CreditItem(
      icon: '🌊',
      name: 'Beach Waves',
      source: 'Pixabay Audio',
      creator: 'Pixabay',
      license: 'CC0',
    ),
    _CreditItem(
      icon: '🫧',
      name: 'Bubble',
      source: 'Freesound.org',
      creator: 'Community',
      license: 'CC0',
    ),
    _CreditItem(
      icon: '🎵',
      name: 'Lo-Fi',
      source: 'Pixabay Audio',
      creator: 'Pixabay',
      license: 'CC0',
    ),
    _CreditItem(
      icon: '🎹',
      name: 'Piano',
      source: 'Pixabay Audio',
      creator: 'Pixabay',
      license: 'CC0',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Credits & License')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Audio Sources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Credit cards
          ..._credits.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            _infoRow(theme, 'Source', c.source),
                            _infoRow(theme, 'Creator', c.creator),
                            _infoRow(theme, 'License', c.license),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Footer
          Center(
            child: Column(
              children: [
                Image.asset('assets/image/applogocream.png',
                    width: 100),
                const SizedBox(height: 6),
                Text(
                  'Built by Christian Elbert',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'Teknik Informatika — Universitas Riau',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }
}

class _CreditItem {
  final String icon;
  final String name;
  final String source;
  final String creator;
  final String license;

  const _CreditItem({
    required this.icon,
    required this.name,
    required this.source,
    required this.creator,
    required this.license,
  });
}
