import 'package:workmanager/workmanager.dart';
import 'package:my_mpt/core/services/notification_service.dart';

/// Callback для фоновой задачи проверки замен
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Инициализируем сервис уведомлений
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Проверяем новые замены
      await notificationService.checkForNewReplacements();

      return Future.value(true);
    } catch (e) {
      // Возвращаем false при ошибке, чтобы workmanager мог повторить попытку
      return Future.value(false);
    }
  });
}

/// Инициализирует фоновые задачи
Future<void> initializeBackgroundTasks() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Регистрируем периодическую задачу
  // Проверка каждые 60 минут (минимальный интервал для Android - 15)
  await Workmanager().registerPeriodicTask(
    'check_replacements',
    'check_replacements',
    frequency: const Duration(minutes: 60),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}
