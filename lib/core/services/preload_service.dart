import 'package:my_mpt/data/datasources/remote/speciality_remote_datasource.dart';
import 'package:my_mpt/data/datasources/remote/group_remote_datasource.dart';

/// Сервис для предзагрузки данных при первом запуске приложения
///
/// Этот сервис загружает все специальности и все группы,
/// чтобы сохранить их в кэш для быстрого доступа
class PreloadService {
  final SpecialityRemoteDatasource _specialityService =
      SpecialityRemoteDatasource();
  final GroupRemoteDatasource _groupService = GroupRemoteDatasource();

  /// Предзагружает все специальности и группы
  ///
  /// Метод загружает все специальности, а затем для каждой специальности
  /// загружает все группы, сохраняя их в кэш
  ///
  /// Возвращает:
  /// Завершается после завершения предзагрузки
  Future<void> preloadAllData() async {
    try {
      // Загружаем все специальности (сохраняются в кэш автоматически)
      final specialties = await _specialityService.parseTabList(
        forceRefresh: true,
      );

      // Для каждой специальности загружаем группы (сохраняются в кэш автоматически)
      // Используем await для последовательной загрузки, чтобы не перегружать сервер
      for (var specialty in specialties) {
        try {
          // Загружаем с forceRefresh = true для предзагрузки
          // Используем позиционный параметр forceRefresh
          await _groupService.parseGroups(specialty.name, true);
          // Небольшая задержка между запросами, чтобы не перегружать сервер
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          // Игнорируем ошибки для отдельных специальностей
          // Продолжаем загрузку остальных
        }
      }
    } catch (e) {
      // Игнорируем ошибки предзагрузки
      // Приложение должно работать даже если предзагрузка не удалась
    }
  }

  /// Предзагружает только специальности
  ///
  /// Возвращает:
  /// Завершается после завершения предзагрузки
  Future<void> preloadSpecialties() async {
    try {
      await _specialityService.parseTabList(forceRefresh: true);
    } catch (e) {
      // Игнорируем ошибки предзагрузки
    }
  }
}
