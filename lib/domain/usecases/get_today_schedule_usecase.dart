import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на сегодня
class GetTodayScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  GetTodayScheduleUseCase(this.repository);

  /// Выполнить получение расписания на сегодня
  Future<List<Schedule>> call({bool forceRefresh = false}) async {
    return await repository.getTodaySchedule(forceRefresh: forceRefresh);
  }
}