import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/domain/repositories/schedule_changes_repository_interface.dart';

/// Получение изменений в расписании
///
/// Этот класс реализует бизнес-логику для получения изменений в расписании
/// с использованием репозитория изменений в расписании
class GetScheduleChangesUseCase {
  /// Репозиторий для работы с изменениями в расписании
  final ScheduleChangesRepositoryInterface repository;

  /// Конструктор use case для получения изменений в расписании
  ///
  /// Параметры:
  /// - [repository]: Репозиторий изменений в расписании
  GetScheduleChangesUseCase(this.repository);

  /// Выполнить получение изменений в расписании
  ///
  /// Метод делегирует выполнение получения изменений в расписании
  /// репозиторию изменений в расписании
  ///
  /// Возвращает:
  /// - Future<List<ScheduleChangeEntity>>: Список изменений в расписании
  Future<List<ScheduleChangeEntity>> call() async {
    return await repository.getScheduleChanges();
  }
}
