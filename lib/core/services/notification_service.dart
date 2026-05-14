import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 42;
  static const _channelId = 'serenify_audio';

  // Callbacks wired from audio_provider
  static void Function()? onPause;
  static void Function()? onStop;

  // MethodChannel to minimize app after handling action
  static const _appChannel = MethodChannel('com.christianelbert.serenify/app_control');

  // Large icon loaded once
  static ByteArrayAndroidBitmap? _largeIcon;

  static Future<void> init() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    // Request notification permission (Android 13+)
    await android?.requestNotificationsPermission();

    // Create silent, low-priority channel
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Serenify',
      description: 'Audio playback controls',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ));

    // Pre-load large icon from assets
    try {
      final bytes = await rootBundle
          .load('assets/image/applogocream.png')
          .then((d) => d.buffer.asUint8List());
      _largeIcon = ByteArrayAndroidBitmap(bytes);
    } catch (_) {
      _largeIcon = null; // Fallback: no large icon
    }
  }

  /// Called when app is in foreground and action button is tapped.
  static void _onAction(NotificationResponse r) {
    if (r.actionId == 'pause') onPause?.call();
    if (r.actionId == 'stop') onStop?.call();
    // Minimize app so it doesn't appear to "open" when button is pressed
    _appChannel.invokeMethod('minimizeApp').catchError((_) {});
  }

  static Future<void> show(String title, {required bool paused}) async {
    await _plugin.show(
      _id,
      'Serenify',
      paused ? '⏸  $title' : '▶  $title',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Serenify',
          icon: '@drawable/ic_notification',
          largeIcon: _largeIcon,
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
              showsUserInterface: true,   // must be true for handler to fire
              cancelNotification: false,
            ),
            const AndroidNotificationAction(
              'stop',
              'Stop',
              showsUserInterface: true,   // must be true for handler to fire
              cancelNotification: false,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> dismiss() => _plugin.cancel(_id);
}

/// Background handler — required top-level function.
/// With showsUserInterface: true the app is already brought to foreground
/// and _onAction handles everything; this is kept as a required stub.
@pragma('vm:entry-point')
void _onBackgroundAction(NotificationResponse r) {}
