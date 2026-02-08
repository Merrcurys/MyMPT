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
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground, // iOS Background Fetch/BGTaskScheduler
    ),
  );

  await service.startService();
}

/// iOS background fetch entry-point.
/// iOS НЕ поддерживает постоянный фоновый сервис как Android: это короткие запуски по решению системы. [web:91]
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.checkForNewReplacements();
  } catch (_) {}

  return true;
}

/// Точка входа для сервиса (Android + iOS foreground)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
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

  // Первая проверка сразу
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.checkForNewReplacements();
  } catch (_) {}

  // Периодическая проверка (на iOS это будет работать только пока приложение реально не “усыплено”)
  Timer.periodic(const Duration(minutes: 60), (timer) async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.checkForNewReplacements();
    } catch (_) {}
  });
}
