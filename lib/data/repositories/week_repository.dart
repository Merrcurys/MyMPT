import 'package:my_mpt/data/services/week_parser_service.dart';
import 'package:my_mpt/data/models/week_info.dart';

class WeekRepository {
  final WeekParserService _parserService = WeekParserService();
  
  /// Get week information by parsing the MPT website
  Future<WeekInfo> getWeekInfo() async {
    try {
      final weekInfo = await _parserService.parseWeekInfo();
      return weekInfo;
    } catch (e) {
      // Return default week info or handle error as appropriate
      return WeekInfo(
        weekType: 'Неизвестно',
        date: 'Неизвестно',
        day: 'Неизвестно',
      );
    }
  }
}