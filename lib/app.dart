import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/audio_provider.dart';
import 'shared/theme/app_theme.dart';
import 'features/home/home_screen.dart';

/// Root widget — MaterialApp dengan theme toggle
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
      home: const HomeScreen(),
    );
  }
}
