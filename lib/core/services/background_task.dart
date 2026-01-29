import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_mpt/core/services/notification_service.dart';

/// Инициализирует фоновый сервис
Future<void> initializeBackgroundTasks() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );

  // ВАЖНО: без этого сервис часто не запускается вообще
  await service.startService();
}

/// Точка входа для фонового сервиса
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // ВАЖНО: без этого плагины (например, уведомления) в фоне могут не работать
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Можно сделать первую проверку сразу при старте сервиса
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.checkForNewReplacements();
  } catch (_) {}

  // Периодическая проверка замен каждые 60 минут
  Timer.periodic(const Duration(minutes: 60), (timer) async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.checkForNewReplacements();
    } catch (_) {
      // Игнорируем ошибки
    }
  });
}
