import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';
import 'package:my_mpt/domain/entities/group.dart';
import 'package:my_mpt/data/repositories/specialty_repository.dart';

class GroupRepository implements GroupRepositoryInterface {
  final MptParserService _parserService = MptParserService();
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

        final result = groupInfos
            .map(
              (groupInfo) => Group(
                code: groupInfo.code,
                specialtyCode: groupInfo.specialtyCode,
              ),
            )
            .toList();

        result.sort((a, b) => a.code.compareTo(b.code));
        return result;
      }

      // Используем имя специальности для поиска групп
      final groupInfos = await _parserService.parseGroups(specialtyName);

      final result = groupInfos
          .map(
            (groupInfo) => Group(
              code: groupInfo.code,
              specialtyCode: groupInfo.specialtyCode,
              // Возможно, нужно добавить другие поля из GroupInfo
            ),
          )
          .toList();

      result.sort((a, b) => a.code.compareTo(b.code));
      return result;
    } catch (e) {
      return [];
    }
  }
}
