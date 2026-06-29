import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton notification service wrapping flutter_local_notifications.
/// Schedules 24-hour and 1-hour deadline reminders for tasks.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Channel constants ──────────────────────────────────────────────────────

  static const String _channelId = 'mindful_scholar_deadlines';
  static const String _channelName = 'Deadline Reminders';
  static const String _channelDescription =
      'Notifications for upcoming task deadlines';

  // ─── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onTap(NotificationResponse response) {
    // TODO: deep-link to tasks screen when notification tapped
    debugPrint('Notification tapped: ${response.id}');
  }

  // ─── Request permission (Android 13+) ───────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS handled at init
  }

  // ─── Schedule notifications ──────────────────────────────────────────────────

  /// Schedules two notifications for a task:
  ///   • 24 hours before deadline
  ///   • 1 hour before deadline
  Future<void> scheduleDeadlineNotifications({
    required int taskId,
    required String taskTitle,
    required String taskType,
    required DateTime deadline,
  }) async {
    if (!_initialized) await init();

    final tz.TZDateTime tzDeadline =
        tz.TZDateTime.from(deadline, tz.local);

    final typeEmoji = _typeEmoji(taskType);
    final typeLabel = _typeLabel(taskType);

    // 24-hour reminder  (notification id = taskId * 10)
    final twentyFourBefore = tzDeadline.subtract(const Duration(hours: 24));
    if (twentyFourBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: taskId * 10,
        title: '$typeEmoji $typeLabel due tomorrow!',
        body: '"$taskTitle" is due in 24 hours. Stay on track! 📚',
        scheduledDate: twentyFourBefore,
      );
    }

    // 1-hour reminder  (notification id = taskId * 10 + 1)
    final oneHourBefore = tzDeadline.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: taskId * 10 + 1,
        title: '⏰ Last hour — $typeLabel due soon!',
        body: '"$taskTitle" is due in 1 hour. Finish strong! 💪',
        scheduledDate: oneHourBefore,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Scheduled notification $id for $scheduledDate');
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  // ─── Cancel notifications ────────────────────────────────────────────────────

  /// Cancel both notifications for a task (called on completion / deletion).
  Future<void> cancelTaskNotifications(int taskId) async {
    await _plugin.cancel(taskId * 10);
    await _plugin.cancel(taskId * 10 + 1);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _typeEmoji(String type) {
    switch (type) {
      case 'assignment':
        return '📚';
      case 'reading':
        return '📖';
      case 'fun':
        return '🎮';
      case 'project':
        return '💼';
      default:
        return '✏️';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'assignment':
        return 'Assignment';
      case 'reading':
        return 'Reading';
      case 'fun':
        return 'Activity';
      case 'project':
        return 'Project';
      default:
        return 'Task';
    }
  }
}
