import 'package:my_mpt/domain/entities/group.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';

/// Получение списка групп по коду специальности
///
/// Этот класс реализует бизнес-логику для получения списка групп
/// по коду специальности с использованием репозитория специальностей
class GetGroupsBySpecialtyUseCase {
  /// Репозиторий для работы со специальностями и группами
  final SpecialtyRepositoryInterface repository;

  /// Конструктор use case для получения списка групп по коду специальности
  ///
  /// Параметры:
  /// - [repository]: Репозиторий специальностей и групп
  GetGroupsBySpecialtyUseCase(this.repository);

  /// Выполнить получение списка групп по коду специальности
  ///
  /// Метод делегирует выполнение получения списка групп
  /// репозиторию специальностей и групп
  ///
  /// Параметры:
  /// - [specialtyCode]: Код специальности
  ///
  /// Возвращает:
  /// - Future<List<Group>>: Список групп для указанной специальности
  Future<List<Group>> call(String specialtyCode) async {
    final result = await repository.getGroupsBySpecialty(specialtyCode);
    return result;
  }
}
