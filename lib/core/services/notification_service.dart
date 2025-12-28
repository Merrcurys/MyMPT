import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_mpt/domain/entities/replacement.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _lastCheckedKey = 'last_checked_replacements';
  static const String _lastNotificationTimeKey = 'last_notification_time';
  static const String _remindersEnabledKey = 'reminders_enabled';

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'replacement_channel',
    'Replacement Notifications',
    description: 'Notifications for schedule replacements',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _localNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  /// Check for new replacements and show notifications if needed
  Future<void> checkForNewReplacements(List<Replacement> currentReplacements) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get previously stored replacements
    final storedReplacementsJson = prefs.getStringList(_lastCheckedKey) ?? [];
    
    // Convert stored JSON strings back to Replacement objects
    final storedReplacements = _deserializeReplacements(storedReplacementsJson);
    
    // Find new replacements
    final newReplacements = _findNewReplacements(storedReplacements, currentReplacements);
    
    // Show notifications for new replacements
    if (newReplacements.isNotEmpty) {
      for (final replacement in newReplacements) {
        await _showLocalReplacementNotification(replacement);
      }
    }
    
    // Update stored replacements
    await prefs.setStringList(_lastCheckedKey, _serializeReplacements(currentReplacements));
  }

  List<Replacement> _deserializeReplacements(List<String> jsonList) {
    return jsonList.map((json) {
      final parts = json.split('|');
      if (parts.length >= 5) {
        return Replacement(
          lessonNumber: parts[0],
          replaceFrom: parts[1],
          replaceTo: parts[2],
          updatedAt: parts[3],
          changeDate: parts[4],
        );
      }
      return Replacement(lessonNumber: '', replaceFrom: '', replaceTo: '', updatedAt: '', changeDate: '');
    }).toList();
  }

  List<String> _serializeReplacements(List<Replacement> replacements) {
    return replacements.map((replacement) {
      return '${replacement.lessonNumber}|${replacement.replaceFrom}|${replacement.replaceTo}|${replacement.updatedAt}|${replacement.changeDate}';
    }).toList();
  }

  List<Replacement> _findNewReplacements(List<Replacement> oldReplacements, List<Replacement> newReplacements) {
    return newReplacements.where((newReplacement) {
      return !oldReplacements.any((oldReplacement) => 
        oldReplacement.lessonNumber == newReplacement.lessonNumber &&
        oldReplacement.replaceFrom == newReplacement.replaceFrom &&
        oldReplacement.replaceTo == newReplacement.replaceTo &&
        oldReplacement.updatedAt == newReplacement.updatedAt &&
        oldReplacement.changeDate == newReplacement.changeDate
      );
    }).toList();
  }

  Future<void> _showLocalReplacementNotification(Replacement replacement) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'replacement_channel',
      'Replacement Notifications',
      channelDescription: 'Notifications for schedule replacements',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New schedule replacement',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      0,
      'Новая замена в расписании',
      'Урок ${replacement.lessonNumber}: ${replacement.replaceFrom} → ${replacement.replaceTo}',
      platformChannelSpecifics,
    );
  }

  /// Clear stored replacement data (for testing or reset)
  Future<void> clearStoredReplacements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckedKey);
  }

  /// Check if we should send a notification based on time (not more than once per hour)
  Future<bool> _shouldSendNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationTimeStr = prefs.getString(_lastNotificationTimeKey);
    
    if (lastNotificationTimeStr == null) {
      return true;
    }
    
    try {
      final lastNotificationTime = DateTime.parse(lastNotificationTimeStr);
      final now = DateTime.now();
      
      // Check if at least 1 hour has passed since last notification
      return now.difference(lastNotificationTime).inHours >= 1;
    } catch (e) {
      // If there's an error parsing the date, assume we can send notification
      return true;
    }
  }

  /// Update the last notification time
  Future<void> _updateLastNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotificationTimeKey, DateTime.now().toIso8601String());
  }

  /// Get if reminders are enabled
  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? true;
  }

  /// Set if reminders are enabled
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);
  }

  /// Show notification about new replacements
  Future<void> showNewReplacementsNotification(int count) async {
    if (count <= 0) return;
    
    final shouldSend = await _shouldSendNotification();
    if (!shouldSend) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'replacement_channel',
      'Replacement Notifications',
      channelDescription: 'Notifications for schedule replacements',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New schedule replacements',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      0,
      'Замены в расписании',
      'Новых замен в расписании: $count',
      platformChannelSpecifics,
    );
    
    await _updateLastNotificationTime();
  }

  /// Show reminder notification about tomorrow's replacements
  Future<void> showTomorrowReplacementsReminder(int count) async {
    if (count <= 0) return;
    
    final remindersEnabled = await areRemindersEnabled();
    if (!remindersEnabled) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'replacement_channel',
      'Replacement Notifications',
      channelDescription: 'Notifications for schedule replacements',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Tomorrow schedule replacements reminder',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      1,
      'Напоминание о заменах',
      'Замен на завтра: $count',
      platformChannelSpecifics,
    );
  }
}