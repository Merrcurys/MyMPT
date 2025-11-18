import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/models/group_info.dart';

class GroupRepository {
  final MptParserService _parserService = MptParserService();

  Future<List<GroupInfo>> getAllGroups() async {
    try {
      final groups = await _parserService.parseGroups();
      return groups;
    } catch (e) {
      return [];
    }
  }

  Future<List<GroupInfo>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      // Используем оптимизированный метод парсера, который фильтрует группы на стороне сервера
      return await _parserService.parseGroups(specialtyCode);
    } catch (e) {
      return [];
    }
  }
}
