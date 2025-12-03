import '../entities/specialty.dart';

/// Интерфейс репозитория для работы со специальностями
abstract class SpecialtyRepositoryInterface {
  /// Получить все специальности
  Future<List<Specialty>> getSpecialties();
}
