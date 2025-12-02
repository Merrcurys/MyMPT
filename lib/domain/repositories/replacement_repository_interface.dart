import 'package:my_mpt/domain/entities/replacement.dart';

/// Интерфейс репозитория для работы с заменами в расписании
abstract class ReplacementRepositoryInterface {
  /// Получить замены в расписании
  Future<List<Replacement>> getScheduleChanges();
}
