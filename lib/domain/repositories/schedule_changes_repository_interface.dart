import 'package:my_mpt/domain/entities/schedule_change.dart';

/// Интерфейс репозитория для работы с изменениями в расписании
abstract class ScheduleChangesRepositoryInterface {
  /// Получить изменения в расписании
  Future<List<ScheduleChangeEntity>> getScheduleChanges();
}