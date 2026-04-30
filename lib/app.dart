import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/audio_provider.dart';
import 'shared/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/presets/presets_screen.dart';
import 'features/timer/timer_screen.dart';

/// Root widget
class SerenifyApp extends ConsumerWidget {
  const SerenifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Serenify',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _AppShell(),
    );
  }
}

/// Shell — splash → main app with bottom nav
class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }
    return const _MainNav();
  }
}

/// Bottom navigation — Home | Presets | Timer
class _MainNav extends StatefulWidget {
  const _MainNav();
  @override
  State<_MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<_MainNav> {
  int _currentIndex = 0;

  // Keep screens alive saat pindah tab (audio tetap jalan)
  final List<Widget> _screens = const [
    HomeScreen(),
    PresetsScreen(),
    TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Presets',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
        ],
      ),
    );
  }
}
