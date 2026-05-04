import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Simple preset playback notification with Pause/Resume and Stop buttons.
/// Only shown when a preset is playing — not for manual soundscape toggles.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 42;
  static const _channelId = 'serenify_preset';

  static void Function()? onPause;
  static void Function()? onStop;

  static Future<void> init() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    // Request permission at runtime (required Android 13+/API 33+)
    await android?.requestNotificationsPermission();

    // Create notification channel
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Serenify',
      description: 'Preset playback controls',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ));
  }

  static void _onAction(NotificationResponse r) {
    if (r.actionId == 'pause') onPause?.call();
    if (r.actionId == 'stop')  onStop?.call();
  }

  static Future<void> show(String presetName, {required bool paused}) async {
    await _plugin.show(
      _id,
      'Serenify',
      paused ? '⏸  $presetName' : '▶  $presetName',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Serenify',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          actions: [
            AndroidNotificationAction(
              'pause',
              paused ? 'Resume' : 'Pause',
              showsUserInterface: true,
              cancelNotification: false,
            ),
            const AndroidNotificationAction(
              'stop',
              'Stop',
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> dismiss() => _plugin.cancel(_id);
}

@pragma('vm:entry-point')
void _onBackgroundAction(NotificationResponse r) {
  // Background taps open the app via showsUserInterface: true
}
