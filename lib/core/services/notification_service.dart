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

  /// Инициализирует сервис уведомлений
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Запрашиваем разрешения для Android 13+
    if (await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false) {
      // Разрешение получено
    }
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Можно добавить навигацию к экрану с заменами
  }

  /// Проверяет новые замены и отправляет уведомления
  Future<void> checkForNewReplacements() async {
    try {
      // Проверяем, включены ли уведомления
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool(_notificationsEnabledKey) ?? true;

      if (!notificationsEnabled) {
        return;
      }

      // Получаем текущие замены
      final currentReplacements =
          await _replacementRepository.getScheduleChanges();

      // Получаем последние проверенные замены
      final lastCheckedReplacements = await _getLastCheckedReplacements();

      // Если это первая проверка, просто сохраняем текущие замены
      if (lastCheckedReplacements.isEmpty) {
        await _saveLastCheckedReplacements(currentReplacements);
        return;
      }

      // Находим новые замены
      final newReplacements = _findNewReplacements(
        currentReplacements,
        lastCheckedReplacements,
      );

      // Если есть новые замены, отправляем уведомление
      if (newReplacements.isNotEmpty) {
        await _showReplacementNotification(newReplacements);
      }

      // Сохраняем текущие замены как последние проверенные
      await _saveLastCheckedReplacements(currentReplacements);
    } catch (e) {
      // Игнорируем ошибки при фоновой проверке
      // чтобы не прерывать работу приложения
    }
  }

  /// Находит новые замены, сравнивая текущие с последними проверенными
  List<Replacement> _findNewReplacements(
    List<Replacement> current,
    List<Replacement> lastChecked,
  ) {
    if (lastChecked.isEmpty) {
      // Если это первая проверка, не отправляем уведомления
      return [];
    }

    // Создаем множество хэшей последних проверенных замен
    final lastCheckedHashes = lastChecked.map((r) => _getReplacementHash(r)).toSet();

    // Находим замены, которых не было в последней проверке
    return current.where((replacement) {
      final hash = _getReplacementHash(replacement);
      return !lastCheckedHashes.contains(hash);
    }).toList();
  }

  /// Создает уникальный хэш для замены
  String _getReplacementHash(Replacement replacement) {
    return '${replacement.lessonNumber}_${replacement.replaceFrom}_${replacement.replaceTo}_${replacement.changeDate}_${replacement.updatedAt}';
  }

  /// Отображает уведомление о новых заменаx
  Future<void> _showReplacementNotification(
    List<Replacement> newReplacements,
  ) async {
    final count = newReplacements.length;
    String title;
    String body;

    if (count == 1) {
      final replacement = newReplacements.first;
      title = 'Новая замена в расписании';
      body =
          'Пара ${replacement.lessonNumber}: ${replacement.replaceFrom} → ${replacement.replaceTo}';
    } else {
      title = 'Новые замены в расписании';
      body = 'Обнаружено новых замен: $count';
    }

    const androidDetails = AndroidNotificationDetails(
      'replacements_channel',
      'Замены в расписании',
      channelDescription: 'Уведомления о новых заменах в расписании',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
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
  Future<void> _saveLastCheckedReplacements(
    List<Replacement> replacements,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        replacements.map((r) => {
          'lessonNumber': r.lessonNumber,
          'replaceFrom': r.replaceFrom,
          'replaceTo': r.replaceTo,
          'updatedAt': r.updatedAt,
          'changeDate': r.changeDate,
        }).toList(),
      );
      await prefs.setString(_lastCheckedReplacementsKey, json);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Получает последние проверенные замены
  Future<List<Replacement>> _getLastCheckedReplacements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_lastCheckedReplacementsKey);

      if (json == null || json.isEmpty) {
        return [];
      }

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

  /// Включает или выключает уведомления
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Проверяет, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Обновляет сохраненные замены (вызывается когда пользователь просматривает замены в приложении)
  Future<void> updateLastCheckedReplacements() async {
    try {
      final currentReplacements =
          await _replacementRepository.getScheduleChanges();
      await _saveLastCheckedReplacements(currentReplacements);
    } catch (e) {
      // Игнорируем ошибки
    }
  }
}
