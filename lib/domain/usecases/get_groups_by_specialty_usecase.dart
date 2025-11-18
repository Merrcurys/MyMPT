import 'package:my_mpt/domain/entities/group.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';

/// Use case для получения списка групп по коду специальности
class GetGroupsBySpecialtyUseCase {
  /// Репозиторий для работы со специальностями и группами
  final SpecialtyRepositoryInterface repository;

  GetGroupsBySpecialtyUseCase(this.repository);

  /// Выполнить получение списка групп по коду специальности
  Future<List<Group>> call(String specialtyCode) async {
    print('DEBUG: Use case получает запрос для специальности: $specialtyCode');
    final result = await repository.getGroupsBySpecialty(specialtyCode);
    print('DEBUG: Use case возвращает ${result.length} групп');
    return result;
  }
}