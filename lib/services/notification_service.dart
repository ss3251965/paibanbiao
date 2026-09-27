import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/day_record.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _plugin.initialize(initializationSettings);

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleNotification(DateTime date, DayRecord record) async {
    if (!record.hasRingtone || record.note.isEmpty) return;

    // 解析用户自定义的时间
    final parts = record.reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduledDate = DateTime(date.year, date.month, date.day, hour, minute);
    
    // 如果设置的时间已经过了，就不提醒
    if (scheduledDate.isBefore(DateTime.now())) return; 

    String soundUri = 'content://settings/system/notification_sound';
    if (record.ringtoneType == '闹钟') {
      soundUri = 'content://settings/system/alarm_alert';
    }

    final androidDetails = AndroidNotificationDetails(
      'banbiao_channel',
      '我的记录提醒',
      channelDescription: '记录事件提醒',
      importance: Importance.max,
      priority: Priority.high,
      sound: UriAndroidNotificationSound(soundUri),
    );

    await _plugin.zonedSchedule(
      date.day, // 用日期作为通知ID，避免覆盖
      record.note,
      record.detail.isEmpty ? '点击查看详情' : record.detail,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}