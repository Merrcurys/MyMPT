import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';

/// Use case для получения расписания на завтра
class GetTomorrowScheduleUseCase {
  /// Единое хранилище для работы с расписанием
  final UnifiedScheduleRepository repository;

  GetTomorrowScheduleUseCase(this.repository);

  /// Выполнить получение расписания на завтра
  Future<List<Schedule>> call({bool forceRefresh = false}) async {
    return await repository.getTomorrowSchedule(forceRefresh: forceRefresh);
  }
}