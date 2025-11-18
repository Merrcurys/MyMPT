import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на неделю
class GetWeeklyScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  GetWeeklyScheduleUseCase(this.repository);

  /// Выполнить получение расписания на неделю
  Future<Map<String, List<Schedule>>> call({bool forceRefresh = false}) async {
    return await repository.getWeeklySchedule(forceRefresh: forceRefresh);
  }
}