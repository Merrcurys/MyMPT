import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/group_info.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/entities/specialty.dart';
import 'package:my_mpt/domain/entities/group.dart';

class MptRepository implements SpecialtyRepositoryInterface {
  final MptParserService _parserService = MptParserService();

  @override
  Future<List<Specialty>> getSpecialties() async {
    try {
      final tabs = await _parserService.parseTabList();
      final specialties = tabs
          .map((tab) => _createSpecialtyFromTab(tab))
          .toList();

      specialties.sort((a, b) => a.name.compareTo(b.name));

      return specialties;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      // Используем оптимизированный метод парсера, который фильтрует группы на стороне сервера
      final groupInfos = await _parserService.parseGroups(specialtyCode);

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
    } catch (e) {
      return [];
    }
  }

  Specialty _createSpecialtyFromTab(TabInfo tab) {
    String code = tab.href;
    if (code.startsWith('#specialty-')) {
      code = code
          .substring(11)
          .toUpperCase()
          .replaceAll('-', '.')
          .replaceAll('E', 'Э');
    }

    String name = tab.name;
    if (name.isEmpty) {
      name = tab.ariaControls;
    }

    return Specialty(code: code, name: name);
  }
}
