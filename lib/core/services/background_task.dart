import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:my_mpt/core/services/notification_service.dart';

/// Временно для тестирования: чаще проверяем и обходим кэш.
const bool _testingFastPolling = true;

/// Как часто проверяем замены в фоне.
///
/// Важно: Android может «сдвигать» таймеры/будить реже (Doze), но foreground service
/// существенно повышает шанс реального выполнения периодической проверки.
const Duration _replacementCheckPeriod =
    _testingFastPolling ? Duration(minutes: 1) : Duration(minutes: 15);

/// Инициализирует фоновый сервис.
///
/// Для надёжной работы на Android запускаем как foreground service.
Future<void> initializeBackgroundTasks() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: 'mpt_bg_service',
      initialNotificationTitle: 'Мой МПТ',
      initialNotificationContent: 'Проверка замен в фоне',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

/// iOS background fetch entry-point.
///
/// iOS не поддерживает постоянный сервис как Android: это короткие запуски по решению системы.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    final notificationService = NotificationService();
    await notificationService.initialize(requestPermission: false);
    await notificationService.checkForNewReplacements(
      forceRefresh: _testingFastPolling,
    );
  } catch (_) {}

  return true;
}

/// Точка входа для сервиса (Android + iOS foreground)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    // По умолчанию работаем как foreground service (иначе Android может быстро убить процесс).
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'Мой МПТ',
      content: 'Проверяю замены…',
    );

    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });

    // Оставляем хук, но в нашем сценарии лучше не уходить в background mode.
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  Future<void> runCheck() async {
    var ok = true;

    try {
      final notificationService = NotificationService();
      await notificationService.initialize(requestPermission: false);
      await notificationService.checkForNewReplacements(
        forceRefresh: _testingFastPolling,
      );
    } catch (_) {
      ok = false;
    }

    if (service is AndroidServiceInstance) {
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      service.setForegroundNotificationInfo(
        title: 'Мой МПТ',
        content: ok ? 'Проверка замен: $hh:$mm' : 'Ошибка проверки: $hh:$mm',
      );
    }
  }

  // Первая проверка сразу
  await runCheck();

  // Периодическая проверка
  Timer.periodic(_replacementCheckPeriod, (_) async {
    await runCheck();
  });
}
