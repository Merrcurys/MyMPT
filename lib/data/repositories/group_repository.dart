import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/models/group_info.dart';

class GroupRepository {
  final MptParserService _parserService = MptParserService();
  
  /// Get all groups by parsing the MPT website
  Future<List<GroupInfo>> getAllGroups() async {
    try {
      final groups = await _parserService.parseGroups();
      return groups;
    } catch (e) {
      // Return empty list or handle error as appropriate
      return [];
    }
  }
  
  /// Get groups by specialty code
  Future<List<GroupInfo>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      final allGroups = await _parserService.parseGroups();
      // Filter groups by specialty code
      return allGroups.where((group) => 
        group.specialtyCode.contains(specialtyCode) || 
        group.specialtyName.contains(specialtyCode)
      ).toList();
    } catch (e) {
      // Return empty list or handle error as appropriate
      return [];
    }
  }
}