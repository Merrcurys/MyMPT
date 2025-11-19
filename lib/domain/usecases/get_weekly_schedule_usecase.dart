import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на неделю
///
/// Этот класс реализует бизнес-логику для получения расписания на неделю
/// с использованием единого хранилища расписания
class GetWeeklyScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  /// Конструктор use case для получения расписания на неделю
  ///
  /// Параметры:
  /// - [repository]: Единое хранилище расписания
  GetWeeklyScheduleUseCase(this.repository);

  /// Выполнить получение расписания на неделю
  ///
  /// Метод делегирует выполнение получения расписания на неделю
  /// единому хранилищу расписания
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительное обновление данных (опционально)
  ///
  /// Возвращает:
  /// - Future<Map<String, List<Schedule>>>: Расписание на неделю, где ключ - день недели
  Future<Map<String, List<Schedule>>> call({bool forceRefresh = false}) async {
    return await repository.getWeeklySchedule(forceRefresh: forceRefresh);
  }
}
