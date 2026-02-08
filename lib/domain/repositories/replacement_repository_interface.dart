import 'package:my_mpt/domain/entities/replacement.dart';

/// Интерфейс репозитория для работы с заменами в расписании
abstract class ReplacementRepositoryInterface {
  /// Получить замены в расписании
  ///
  /// forceRefresh:
  /// - false: можно использовать кэш (обычный режим)
  /// - true: принудительно обновить с сервера (удобно для тестов)
  Future<List<Replacement>> getScheduleChanges({bool forceRefresh = false});
}
