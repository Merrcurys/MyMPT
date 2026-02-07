import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_mpt/data/repositories/replacement_repository.dart';
import 'package:my_mpt/domain/entities/replacement.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления уведомлениями о новых заменах
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final ReplacementRepository _replacementRepository = ReplacementRepository();

  static const String _lastCheckedReplacementsKey = 'last_checked_replacements';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Android channel for replacement notifications
  static const String _channelId = 'replacements_channel';
  static const String _channelName = 'Замены в расписании';
  static const String _channelDescription =
      'Уведомления о новых заменах в расписании';

  // Android channel for foreground background service notification
  // Must exist before starting a foreground service on Android 8+.
  static const String _serviceChannelId = 'mpt_bg_service';
  static const String _serviceChannelName = 'Фоновая проверка';
  static const String _serviceChannelDescription =
      'Служебное уведомление для фоновой проверки замен';

  bool _initialized = false;

  /// Инициализирует сервис уведомлений
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Создаём каналы на Android (важно для Android 8+)
    const replacementsChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    const serviceChannel = AndroidNotificationChannel(
      _serviceChannelId,
      _serviceChannelName,
      description: _serviceChannelDescription,
      importance: Importance.low,
    );

    await androidImpl?.createNotificationChannel(replacementsChannel);
    await androidImpl?.createNotificationChannel(serviceChannel);

    // Запрашиваем разрешения для Android 13+
    // (Если пользователь запретил — show() не покажет ничего)
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Можно добавить навигацию к экрану с заменами
  }

  /// Проверяет новые замены и отправляет уведомления
  ///
  /// notifyIfFirstCheck:
  /// - false: первая проверка просто сохраняет состояние, не уведомляет (как было)
  /// - true: если это первая проверка и замены не пустые, уведомляем сразу (для сценария смены группы)
  Future<void> checkForNewReplacements({
    bool notifyIfFirstCheck = false,
  }) async {
    try {
      await initialize();

      // Проверяем, включены ли уведомления логически (настройка приложения)
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool(_notificationsEnabledKey) ?? true;
      if (!notificationsEnabled) return;

      final currentReplacements = await _replacementRepository
          .getScheduleChanges();

      final lastCheckedReplacements = await _getLastCheckedReplacements();

      if (lastCheckedReplacements.isEmpty) {
        if (notifyIfFirstCheck && currentReplacements.isNotEmpty) {
          await _showReplacementNotification(currentReplacements);
        }
        await _saveLastCheckedReplacements(currentReplacements);
        return;
      }

      final newReplacements = _findNewReplacements(
        currentReplacements,
        lastCheckedReplacements,
      );

      if (newReplacements.isNotEmpty) {
        await _showReplacementNotification(newReplacements);
      }

      await _saveLastCheckedReplacements(currentReplacements);
    } catch (e) {
      // Игнорируем ошибки при фоновой проверке
    }
  }

  /// Находит новые замены, сравнивая текущие с последними проверенными
  List<Replacement> _findNewReplacements(
    List<Replacement> current,
    List<Replacement> lastChecked,
  ) {
    if (lastChecked.isEmpty) return [];

    final lastCheckedHashes = lastChecked
        .map((r) => _getReplacementHash(r))
        .toSet();

    return current.where((replacement) {
      final hash = _getReplacementHash(replacement);
      return !lastCheckedHashes.contains(hash);
    }).toList();
  }

  /// Создает уникальный хэш для замены
  String _getReplacementHash(Replacement replacement) {
    return '${replacement.lessonNumber}_${replacement.replaceFrom}_${replacement.replaceTo}_${replacement.changeDate}_${replacement.updatedAt}';
  }

  /// Отображает уведомление о новых заменах
  Future<void> _showReplacementNotification(List<Replacement> reps) async {
    final count = reps.length;

    final title = count == 1
        ? 'Новая замена в расписании'
        : 'Новые замены в расписании';

    final body = count == 1
        ? 'Пара ${reps.first.lessonNumber}: ${reps.first.replaceFrom} → ${reps.first.replaceTo}'
        : 'Обнаружено новых замен: $count';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  /// Сохраняет последние проверенные замены
  Future<void> _saveLastCheckedReplacements(List<Replacement> reps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        reps
            .map(
              (r) => {
                'lessonNumber': r.lessonNumber,
                'replaceFrom': r.replaceFrom,
                'replaceTo': r.replaceTo,
                'updatedAt': r.updatedAt,
                'changeDate': r.changeDate,
              },
            )
            .toList(),
      );
      await prefs.setString(_lastCheckedReplacementsKey, json);
    } catch (e) {}
  }

  /// Получает последние проверенные замены
  Future<List<Replacement>> _getLastCheckedReplacements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_lastCheckedReplacementsKey);
      if (json == null || json.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((item) {
        return Replacement(
          lessonNumber: item['lessonNumber'] as String,
          replaceFrom: item['replaceFrom'] as String,
          replaceTo: item['replaceTo'] as String,
          updatedAt: item['updatedAt'] as String,
          changeDate: item['changeDate'] as String,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> updateLastCheckedReplacements() async {
    try {
      final currentReplacements = await _replacementRepository
          .getScheduleChanges();
      await _saveLastCheckedReplacements(currentReplacements);
    } catch (e) {}
  }
}
