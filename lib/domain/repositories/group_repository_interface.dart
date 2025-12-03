import '../../data/models/group.dart';

/// Интерфейс репозитория для работы с группами
abstract class GroupRepositoryInterface {
  /// Получить группы по коду специальности
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode);
}
