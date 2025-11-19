import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на сегодня
///
/// Этот класс реализует бизнес-логику для получения расписания на сегодня
/// с использованием единого хранилища расписания
class GetTodayScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  /// Конструктор use case для получения расписания на сегодня
  ///
  /// Параметры:
  /// - [repository]: Единое хранилище расписания
  GetTodayScheduleUseCase(this.repository);

  /// Выполнить получение расписания на сегодня
  ///
  /// Метод делегирует выполнение получения расписания на сегодня
  /// единому хранилищу расписания
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительное обновление данных (опционально)
  ///
  /// Возвращает:
  /// - Future<List<Schedule>>: Список элементов расписания на сегодня
  Future<List<Schedule>> call({bool forceRefresh = false}) async {
    return await repository.getTodaySchedule(forceRefresh: forceRefresh);
  }
}
