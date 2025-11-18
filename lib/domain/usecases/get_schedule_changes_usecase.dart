import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/domain/repositories/schedule_changes_repository_interface.dart';

/// Use case для получения изменений в расписании
class GetScheduleChangesUseCase {
  /// Репозиторий для работы с изменениями в расписании
  final ScheduleChangesRepositoryInterface repository;

  GetScheduleChangesUseCase(this.repository);

  /// Выполнить получение изменений в расписании
  Future<List<ScheduleChangeEntity>> call() async {
    return await repository.getScheduleChanges();
  }
}