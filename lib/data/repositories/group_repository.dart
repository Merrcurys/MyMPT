import 'package:my_mpt/data/datasources/remote/mpt_remote_datasource.dart';
import 'package:my_mpt/data/models/group.dart';
import 'package:my_mpt/data/repositories/specialty_repository.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';

class GroupRepository implements GroupRepositoryInterface {
  final MptRemoteDatasource _parserService = MptRemoteDatasource();
  final SpecialtyRepository _specialtyRepository = SpecialtyRepository();

  @override
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      // Получаем имя специальности по коду из кэша специальностей
      final specialtyName = _specialtyRepository.getSpecialtyNameByCode(
        specialtyCode,
      );

      if (specialtyName == null) {
        // Если имя не найдено в кэше, загружаем специальности
        await _specialtyRepository.getSpecialties();
        // Повторно пробуем получить имя
        final retryName = _specialtyRepository.getSpecialtyNameByCode(
          specialtyCode,
        );
        if (retryName == null) {
          return [];
        }

        // Используем имя специальности для поиска групп
        final groupInfos = await _parserService.parseGroups(retryName);

        groupInfos.sort((a, b) => a.code.compareTo(b.code));
        return groupInfos;
      }

      // Используем имя специальности для поиска групп
      final groupInfos = await _parserService.parseGroups(specialtyName);

      groupInfos.sort((a, b) => a.code.compareTo(b.code));
      return groupInfos;
    } catch (e) {
      return [];
    }
  }
}
