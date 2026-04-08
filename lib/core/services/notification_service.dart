import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'water_reminder_channel';
  static const String _channelName = 'Water Reminders';
  static const String _channelDescription =
      'Periodic reminders to drink water throughout the day';

  static const int _baseReminderId = 1000;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (e) {
      debugPrint('⚠️ Failed to get timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleWaterReminders({
    int intervalHours = 2,
    int startHour = 8,
    int endHour = 22,
    bool skipToday = false,
  }) async {
    await cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);
    int slotIndex = 0;

    for (int hour = startHour; hour <= endHour; hour += intervalHours) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (skipToday || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final messages = _reminderMessages;
      final message = messages[slotIndex % messages.length];

      await _plugin.zonedSchedule(
        id: _baseReminderId + slotIndex,
        title: '💧 Time to Hydrate!',
        body: message,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      slotIndex++;
    }

    debugPrint(
      '✅ Scheduled $slotIndex water reminders ($startHour:00 - $endHour:00, every ${intervalHours}h)',
    );
  }

  Future<void> syncWaterReminders({bool skipToday = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final enabled = data['waterReminders'] ?? true;

        if (!enabled) {
          await cancelWaterReminders();
          return;
        }

        final interval = data['reminderInterval'] ?? 2;
        await scheduleWaterReminders(
          intervalHours: interval,
          skipToday: skipToday,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync water reminders: $e');
    }
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 12; i++) {
      await _plugin.cancel(id: _baseReminderId + i);
    }
    debugPrint('🗑️ Cancelled all water reminders');
  }

  Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      id: 0,
      title: '💧 Water Reminder',
      body: 'This is a test notification. Stay hydrated!',
      notificationDetails: details,
    );
  }

  Future<bool> hasActiveReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any(
      (r) => r.id >= _baseReminderId && r.id < _baseReminderId + 12,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  List<String> get _reminderMessages => const [
    'Your body needs water to stay energized! 🏋️',
    'A glass of water boosts your metabolism 🔥',
    'Stay hydrated for better workout performance 💪',
    'Water helps your muscles recover faster 🧊',
    'Drinking water improves focus and energy ⚡',
    'Keep sipping! Your body will thank you 🙌',
    'Hydration is key to reaching your fitness goals 🎯',
    'Time for a water break! You\'ve earned it 🥤',
  ];
}
