import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_mpt/core/services/notification_service.dart';

/// Сервис FCM: токен, разрешения, сохранение в Firestore (token + groupCode),
/// обработка входящих сообщений (foreground — показ через локальное уведомление).
class FcmFirestoreService {
  static const String _selectedGroupKey = 'selected_group';
  static const String _collectionFcmTokens = 'fcm_tokens';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  bool _initialized = false;

  /// Регистрирует background-обработчик (вызывать один раз из main до runApp).
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Инициализация: разрешения, подписка на foreground, обновление токена.
  Future<void> initialize() async {
    if (_initialized) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Сообщения в foreground — показываем локальным уведомлением
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Открытие уведомления (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _messaging.getToken().then((token) {
      if (token != null) _syncTokenWithGroup(token);
    });

    _messaging.onTokenRefresh.listen(_syncTokenWithGroup);

    _initialized = true;
  }

  /// Синхронизирует текущий FCM-токен и выбранную группу в Firestore.
  /// Вызывать при старте приложения и при смене группы в настройках.
  Future<void> syncTokenWithGroup() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _syncTokenWithGroup(token);
  }

  Future<void> _syncTokenWithGroup(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupCode = prefs.getString(_selectedGroupKey) ?? '';

      final docId = _tokenToDocId(token);
      await _firestore.collection(_collectionFcmTokens).doc(docId).set({
        'token': token,
        'groupCode': groupCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  String _tokenToDocId(String token) {
    return token.replaceAll('/', '_');
  }

  void _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final enabled = await _notificationService.areNotificationsEnabled();
    if (!enabled) return;
    await _notificationService.showNotification(
      notification.title ?? 'Мой МПТ',
      notification.body ?? '',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // При желании можно открыть конкретный экран (например, с заменами).
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Обработка в фоне/при закрытом приложении — система сама показывает уведомление.
}
