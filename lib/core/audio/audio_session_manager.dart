import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Setup dan manage audio session untuk handle interruptions
class AudioSessionManager {
  /// Initialize audio session dengan konfigurasi untuk ambient/playback
  static Future<void> init({
    required VoidCallback onPause,
    required VoidCallback onResume,
    required Function(double) onDuck,
  }) async {
    final session = await AudioSession.instance;

    // Konfigurasi sebagai music/ambient player
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));

    // Handle interruptions (telepon masuk, alarm, dll)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Turunkan volume
            onDuck(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Pause semua audio
            onPause();
            break;
        }
      } else {
        // Interruption selesai — resume
        onDuck(1.0);
        onResume();
      }
    });

    // Handle saat audio device berubah (headphone dicabut)
    session.becomingNoisyEventStream.listen((_) {
      onPause();
    });

    // Activate session
    await session.setActive(true);
  }
}
