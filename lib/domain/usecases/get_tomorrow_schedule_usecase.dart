import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на завтра
///
/// Этот класс реализует бизнес-логику для получения расписания на завтра
/// с использованием единого хранилища расписания
class GetTomorrowScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  /// Конструктор use case для получения расписания на завтра
  ///
  /// Параметры:
  /// - [repository]: Единое хранилище расписания
  GetTomorrowScheduleUseCase(this.repository);

  /// Выполнить получение расписания на завтра
  ///
  /// Метод делегирует выполнение получения расписания на завтра
  /// единому хранилищу расписания
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительное обновление данных (опционально)
  ///
  /// Возвращает:
  /// - Future<List<Schedule>>: Список элементов расписания на завтра
  Future<List<Schedule>> call({bool forceRefresh = false}) async {
    return await repository.getTomorrowSchedule(forceRefresh: forceRefresh);
  }
}
